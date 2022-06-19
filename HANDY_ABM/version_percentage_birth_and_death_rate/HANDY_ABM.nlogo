;; ========================================================================================================SIMPLE HANDY MODEL======================================================================================================================
;; Please read the info section of the model to undersatnd what are the underlying logics in the model that has been put for each agents (commoners, elites and nature). A brief description has been provided in this section for completness.  ;;
;; Further description is in the documentation of the model and info section of this netlogo file.                                                                                                                                               ;;
;; A. Commoners rules: --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------;;
;; 1. This model has birth rate where commoners and elites are generated in the model regardless of their wealth status at a fixed rate.
;; 2. The death rate also depend on the (wealth / wealth threshold) ratio. If the ratio is smaller than one then there is famine rules in the simulation and agents die at a higher rate.                                                        ;;
;; 3. The commoners produce wealth from the nature/patch they are on. They use the wealth to pay salary and rest of the wealth is accumulated as a global parameter in the HANDY model.                                ;;

;; B. Elite rules: ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------;;
;; 1. elites pay/consume a higher salary than commoners.
;; 2. elites don't produce wealth from the nature. They are just born, consume and die.
;;==================================================================================================================================================================================================================================================
extensions [vid]  ;; export a 30 frame movie of the view

globals[
  wealth                        ;; globally accessible by all the turtles (agents) in the model.
  wealth-value
  famine-factor                 ;; famine-factor, def: a number that is multiplied to the sustenance cost to get the wealth-threshold-value.
  wealth-threshold              ;; it is a macroscopic parameter. Below this wealth the agent acts under famine condition rules in HANDY.
  inequality-factor             ;; it is the factor which determines what proportion of money is taken by elite from the commoners. Hence, it is a number between 0 to 100.
  famine-check                  ;; wealth / wealth-threshold
  nominal-birth-rate            ;; nominal birth rate in HANDY set to 3%
  nominal-death-rate            ;; nominal death rate in HANDY is set to 1%
  famine-max-death-rate         ;; maximum death rate in HANDY famine is 7%
]
;;xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx BREEDS IN THE MODEL ARE DEFINED BELOW xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

breed [ commoners commoner ]                  ;; they extract nature to produce wealth
breed [ elites elite ]                        ;; they prey on commoners for their wealth
;breed [ banks bank ]                         ;; keeps the wealth at an invisible location

;; xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx PROPERTIES OWNED BY THE BREEDS IN THE MODEL xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
;;turtles-own [ salary wealth ]                 ;; agents own wealth which is accumulated by extraction from nature. They extract Eco Dollars (ED) fron nature, pay themselve some salary.
                                              ;; The proportion of extraction thats is used to pay salary is decided by multiplying a factor called "salary-depletion-factor-ratio" to the extraction from nature.
                                              ;; Some of the salary is then used for sustanance and rest for accumulation of wealth.
                                              ;; When the wealth accumulated by commoner hits a famine threshold, commoner reduce their consumption/salary. This kicks off an increase in their death rate.
                                              ;; salary = extraction * 0.5
                                              ;; salary = sustenance-cost + addition-to-wealth.

patches-own [ nature-amount ]                 ;; patches have nature

;; xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
to start-recording
  carefully [ vid:start-recorder ] [ user-message error-message ]
end

to reset-recorder
  let message (word
    "If you reset the recorder, the current recording will be lost."
    "Are you sure you want to reset the recorder?")
  if vid:recorder-status = "inactive" or user-yes-or-no? message [
    vid:reset-recorder
  ]
end

to save-recording
  if vid:recorder-status = "inactive" [
    user-message "The recorder is inactive. There is nothing to save."
    stop
  ]
  ; prompt user for movie location
  user-message (word
    "Choose a name for your movie file (the "
    ".mp4 extension will be automatically added).")
  let path user-new-file
  if not is-string? path [ stop ]  ; stop if user canceled
  ; export the movie
  carefully [
    vid:save-recording path
    user-message (word "Exported movie to " path ".")
  ] [
    user-message error-message
  ]
end
;; ================================================================ PROCEDURE TO SETUP THE INITIAL MODEL WORLD =====================================================================================================================================
to setup
  clear-all
;;-------------------------------- Some of the globals are soft-coded because we don't want the users of model to mess up with them --------------------------------------------------
    set famine-factor 10
    set nominal-birth-rate  0.03            ;; nominal birth rate in HANDY set to 3%
    set nominal-death-rate  0.01            ;; nominal death rate in HANDY is set to 1%
    set famine-max-death-rate 0.07          ;; maximum death rate in HANDY famine is 7%
    set inequality-factor inequality--factor                                                                                                          ;; it sets the elite salary inequality-factor times commoners.
    set wealth-threshold (number-of-elites * inequality-factor * min-consumption) + (number-of-commoners * min-consumption)                           ;; wealth threshold for agents to trigger famine.
    ask patches [
    set nature-amount nature's-capacity                                                                                                               ;; give nature to the patches, color it shades of green
    recolor-nature                                                                                                                                    ;; recolor the world green as per the nature scale
  ]
  create-commoners number-of-commoners [     ;; create the initial commoners
    ifelse (random-location = true)
    [setxy random-xcor random-ycor]            ;; sets the location to be random cordinates in the initial condition
    [setxy 0 0]
    set color red                            ;; sets the color of commoners to be red
    set shape "person"                       ;; sets the shape of elites to be of a person
  ]
  create-elites number-of-elites [           ;; create the initial elites
    ifelse (random-location = true)
    [setxy random-xcor random-ycor]            ;; sets the location to be random cordinates in the initial condition
    [setxy 0 0]
    set color yellow                         ;; sets the color of commoners to be red
    set shape "wolf"                         ;; sets the shape of elites to be wolf
    set size 2                               ;; increase their size so they are a little easier to see
  ]
  reset-ticks
end

;; recolor the nature to indicate how much has been eaten
to recolor-nature
  set pcolor scale-color green nature-amount 1 20
end

;;====================================================initiate-HANDY-world-commands in order====================================

to initiate-HANDY-world
  ask turtles [
   wiggle
    ifelse movement
    [move]
    []
  ]
  ask commoners [
   extract-nature
   pay-commoners-salary
  ]
  ask elites[
  pay-elites-salary
  ]
  ask patches
  [regrow-nature]
  tick
  hand-update-plots
end

;; turtle procedure, the agent changes its heading. The wiggle and move code is shared by both commoners and elites.
to wiggle                                                                                  ;; turn right then left, so the average is straight ahead
  rt random 90
  lt random 90
end

to move
  fd 1
end

;; commoners procedure, commoners exract nature
to extract-nature
    if (nature-amount > 0)
    ;; decrement the nature
    [set nature-amount nature-amount - depletion-factor * nature-amount                                       ;; - delta* y* xc (term in Eq. 3) of HANDY paper.
    set wealth wealth + depletion-factor * nature-amount]                                                     ;; wealth accumulated
    recolor-nature
end

to pay-commoners-salary
  if wealth > 0
  [set wealth wealth - sustenance-cost]                                                                       ;; decrement the acumulated wealth
end

to pay-elites-salary
  if wealth > 0
  [set wealth wealth - (inequality-factor * sustenance-cost)]                                                 ;; decrement the acumulated wealth
end

;; ======================================================================================== The Model Engine ======================================================================================================================

to go
 ;handy-birth-death
 set famine-check wealth / wealth-threshold
 ifelse ( famine-check > 1 or famine-check = 1)
        [no-famine-rules] ;print "no famine"]
        [famine-rules] ;print "famine"]
ask patches
  [regrow-nature]
 hand-update-plots

tick
export-plot "population with time" "population.csv"
export-plot "Wealth" "wealth.csv"
export-plot "Nature with time" "nature.csv"
end

;;; keep birth and death together
;;  handy-birth code for all agents
to handy-birth-death
  ;print "Yes"
  if count commoners > 0
    [;print (count commoners)
      let xcb (count commoners) * nominal-birth-rate
      ;print xcb
      let xcd (count commoners) * nominal-death-rate
      ;print xcd
      let diff round(xcb - xcd)
      ;print xcb - xcd
      if diff > 1
      [ask one-of commoners
        [hatch diff]]]
    ;print count commoners
    if count elites > 0
   [ let xcb (count elites) * nominal-birth-rate
      let xcd (count elites) * nominal-death-rate
      let diff round (xcb - xcd)
      ;print xcb - xcd
      if diff > 0
      [ask one-of elites
      [hatch diff]]]
end

to no-famine-rules
  handy-birth-death
  ask commoners[
    wiggle
    ifelse movement
    [move]
    []
    extract-nature
    pay-commoners-salary
  ]
  ask elites[
    wiggle
    ifelse movement
    [move]
    []
    pay-elites-salary
  ]

end

to famine-rules
  handy-birth-death
  handy-famine-birth-death-commoner
  handy-famine-birth-death-elites
  ask commoners[
     wiggle
     ifelse movement
    [move]
    []
    extract-nature
    pay-commoners-salary-famine
              ]
  ask elites[
      ;print "this"
      wiggle
      ifelse movement
      [move]
      []
      pay-elites-salary-famine
            ]
end

to handy-famine-birth-death-commoner
  if count commoners > 0
  [let num ((1 - famine-check ) * (famine-max-death-rate - nominal-death-rate) + nominal-death-rate) * (count commoners)
    ifelse num > 1
    [ask n-of (num) commoners [die]]
    [ask commoners [die]]
  ]
end


to handy-famine-birth-death-elites
  if (count elites > 0 and ((count commoners) = 0 ))
      [let num ((1 - famine-check ) * (famine-max-death-rate - nominal-death-rate) + nominal-death-rate) * (count elites)
        ifelse num > 1
        [ask n-of (num) elites [die]]
        [ask elites [die]]
  ]
end

to pay-commoners-salary-famine
  if wealth > 0
  [set wealth wealth - (abs famine-check) * sustenance-cost]                                                                            ;; decrement the acumulated wealth
end

to pay-elites-salary-famine
  if wealth > 0
  [set wealth wealth - (inequality-factor * (abs famine-check) * sustenance-cost)]                                                      ;; decrement the acumulated wealth
end

to regrow-nature
  ifelse nature-amount < nature's-capacity
    [set nature-amount nature-amount + regeneration-rate-of-nature * nature-amount * (nature's-capacity - nature-amount)]               ;; somehow the logistic form started working
  [set nature-amount nature's-capacity]
end

;;============================================================================================= Auxiliary Codes ====================================================================================================================

to hand-update-plots

  set-current-plot "Wealth"
  set-current-plot-pen "wealth"
  ifelse (wealth > 0)
  [plot wealth]
  []


  set-current-plot "Population with time"
  set-current-plot-pen "Commoners"
  plot count commoners
  set-current-plot-pen "Elites"
  plot count elites


  set-current-plot "Nature with time"
  set-current-plot-pen "nature"
  ifelse random-location and movement
  [plot sum[nature-amount] of patches]
  [plot [nature-amount] of patch 0 0]

end


;; ========================================================== Reporters and monitors =================================================================================================================================================

to-report commoners-population
  report count commoners
end

to-report elites-population
  report count elites
end

to-report nature
  report sum[nature-amount] of patches
end

to-report wealth-amount
  report wealth
end

to-report consumption
  ifelse famine-check > 1
  [set wealth-value number-of-elites * inequality-factor * sustenance-cost + number-of-commoners * sustenance-cost]
  [set wealth-value number-of-elites * inequality-factor * sustenance-cost * famine-check + number-of-commoners * min-consumption * famine-check]
  report wealth-value
end

to-report wealth-threshold-factor
  report wealth-threshold
end

to-report famine-check-monitor
  report famine-check
end

;; ==================================================== Exports of the plots ===========================================================================================================================================================

;; plots will be exported to the folder "HANDY_ABM plots"




; Copyright 2022 Suman Saurabh (saurabh@utexas.edu)
@#$#@#$#@
GRAPHICS-WINDOW
865
55
1293
484
-1
-1
20.0
1
10
1
1
1
0
1
1
1
-10
10
-10
10
1
1
1
ticks
30.0

SLIDER
36
207
208
240
number-of-elites
number-of-elites
0
100
0.0
1
1
NIL
HORIZONTAL

BUTTON
71
37
138
70
SETUP
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
146
37
209
70
GO
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
37
498
457
793
Population with time
Time ( ticks in netlogo world)
Units of each parameter (-)
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Commoners" 1.0 0 -8053223 true "" "plot count commoners"
"Elites" 1.0 0 -4079321 true "" "plot count elites"

TEXTBOX
438
160
542
185
CONTROLS
20
0.0
1

TEXTBOX
394
443
616
466
MONITORS AND PLOTS
20
0.0
1

TEXTBOX
1018
26
1138
51
SIMULATION
20
0.0
1

MONITOR
1347
256
1484
301
Elites Population
elites-population
1
1
11

MONITOR
1346
190
1525
235
Wealth Threshold
wealth-threshold-factor
6
1
11

MONITOR
1347
124
1486
169
Commoners Population
commoners-population
1
1
11

SLIDER
218
207
396
240
nature's-capacity
nature's-capacity
0
100
100.0
1
1
ED
HORIZONTAL

MONITOR
1348
314
1489
359
Nature
nature
1
1
11

MONITOR
1542
189
1722
234
Famine Monitor (if less than 1)
famine-check-monitor
1
1
11

MONITOR
1512
316
1689
361
Wealth
wealth-amount
3
1
11

PLOT
477
497
859
793
Wealth
Time (Year)
Eco Dollars (ED)
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"wealth" 1.0 0 -16777216 true "" "plot wealth"

PLOT
880
496
1294
799
Nature with time
Time (ticks / hours)
Nature
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"nature" 1.0 0 -16777216 true "" "  ifelse random-location and movement \n  [plot sum[nature-amount] of patches]\n  [plot [nature-amount] of patch 0 0]"

SWITCH
1156
17
1288
50
movement
movement
1
1
-1000

SLIDER
403
208
575
241
inequality--factor
inequality--factor
0
10
1.0
1
1
NIL
HORIZONTAL

SWITCH
865
17
1009
50
random-location
random-location
1
1
-1000

BUTTON
1516
543
1694
576
START VIDEO CAPTURING
start-recording
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1565
635
1690
668
SAVE THE VIDEO
save-recording
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1351
543
1471
588
vid:recorder-status
vid:recorder-status
17
1
11

BUTTON
1514
588
1693
621
RESET VIDEO RECORDING
reset-recorder
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
37
327
192
387
min-consumption
0.005
1
0
Number

INPUTBOX
216
329
371
389
sustenance-cost
5.0E-4
1
0
Number

INPUTBOX
400
330
555
390
depletion-factor
5.0E-6
1
0
Number

INPUTBOX
36
251
193
311
number-of-commoners
100.0
1
0
Number

INPUTBOX
217
251
372
311
regeneration-rate-of-nature
0.01
1
0
Number

MONITOR
1511
259
1689
304
Consumption
consumption
3
1
11

@#$#@#$#@
## WHAT IS IT?

This agent based model has dynamics of three agents, nature, commoners and elites. The nature is uniformly distributed wealth source in the model. The commoners move in the model/world (a wrap aroud world, like our earth) and harvest the nature for wealth. The nature regenerates itself with time at a fixed rate to a maximum amount at any location. Commoners/Elites (two types of human agents in the model) reproduce other commoners at a fixed rate in the model. Both have a variable death rate, a cosntant value if there is no famine and if there is famine, both agents die at a higher rate. 

What is a famine in the model? 

Like HANDY model, this agents-based model, tracks the total amount of wealth created by the extraction of nature by the commoners. The extracted wealth is used to pay salary (consumption) by agents in the model. If the total amount of wealth reaches below what is required for minimum consumption for each agent in the model, then a condition of "famine" kicks in.Under this consition, agents reduce their consumption and they starts to die at a faster rate. 

The model is aimed to explore the microscopic algorithhms that leads to the same phenomenon reported in HANDY model. [ref presented in the interface]. 

## HOW IT WORKS

- Several agents (commoners and elites) are generated in the model in the beginning. This is decided by the modeler as a play paramter. 
- Resources/Nature like mentioned earlier is genrated uniformly equally to the maximum amount at the beginnig of the model. 
- Agents move (optional) every tick and produce wealth from the patches they are currently on. They use the wealth to pay themselves a salary - "an abstraction for consumption of energy/resource".
- Elites are other agents who pay a higher salary to themselves from the wealth pot without contributing to the extraction of the nature.  
- Like in HANDY model, if for an agent, their accumulated wealth is less than a wealth-threshold, it leads to famine conditions. Famine conditions leads to higher death rate of the agents.
  ====================================================================================
  How much is this sufficient wealth ? 

The sufficient wealth or wealth threshold is the amount of wealth that can suport minimum sustanance of all the agents, commoners and elites in the world at that time. 

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

- Resurces of different types/quality which can regerate at differnt rates can be added to the model.
- Creation of pollution because of higher rate of extraction leading to increased death rate and decreased nature's maximum amount
- Sudden technology development which can increases efficieny and resource base be added to the model. This feature can explain the "Jevon's paradox".

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

- **Wilensky, U. (1997). NetLogo Wolf Sheep Predation model. http://ccl.northwestern.edu/netlogo/models/WolfSheepPredation. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## CREDITS AND REFERENCES

References

- Human and nature dynamics (HANDY): Modeling inequality and use of
resources in the collapse or sustainability of societies. (2014). Safa Motesharrei,Jorge Rivas, Eugenia Kalnay. Ecological Economics, vol 101, pp: 92-102.

## AUTHORSHIP AND CORE IDEA DEVELOPEMNT

Author: Suman Saurabh (saurabh@utexas.edu)
Code Idea Development: Micro to Macro Initiative Team at Energy Institute, University of Texas at Austin. (Dr. Carey King, Prof. Micheal Marder, Prof. Larry Lake).
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
