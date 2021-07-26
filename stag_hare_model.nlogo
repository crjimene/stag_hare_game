breed [hunters hunter]
breed [stags stag]
breed [hares hare]

globals [
  STAG_TYPE
  HARE_TYPE
  MAXIMUM_ENERGY
  stag_introduction_counter
  hare_introduction_counter
  stag_speed
  hare_speed
]

hunters-own [
  energy ;Life of individual
  target_type ;Stag 0 Hare 1
  partnered? ;Hunting with anyone?
  leading? ;leading or following partner?
  partner ;Hunting partner
  time_to_reproduce ;countdown till hunter clone itself
  reproduced? ;indicates if hunter has already cloned itself or not
]

to setup
  clear-all
  set STAG_TYPE 0
  set HARE_TYPE 1
  set-default-shape hunters "person"
  set-default-shape hares "rabbit2"
  set-default-shape stags "sheep 2"
  set stag_introduction_counter 0
  set hare_introduction_counter 0
  set stag_speed 0.18
  set hare_speed 0.18
  grow-stags-and-hares
  create-hunters stags_hunters_number [ ;;Create stag hunters
    set target_type STAG_TYPE
    set color brown
    setxy random-xcor random-ycor
    set energy starting_hunters_energy
    set partnered? false
    set leading? false
    set partner nobody
    set time_to_reproduce hunters_reproduction_delay
    set reproduced? false
  ]

  create-hunters hares_hunters_number [ ;;Create stag hunters
    set target_type HARE_TYPE
    set color white
    setxy random-xcor random-ycor
    set energy starting_hunters_energy
    set partnered? false
    set leading? false
    set partner nobody
    set time_to_reproduce hunters_reproduction_delay
    set reproduced? false
  ]

  reset-ticks
end

to move-stags-and-hares

  ask stags [
    ifelse ( ycor <= ( min-pycor + 1 ) ) [
      die
    ]
    [
      set ycor ycor - stag_speed
    ]
  ]
  ask hares [
    ifelse ( ycor <= ( min-pycor + 1 ) ) [
      die
    ]
    [
      set ycor ycor - hare_speed
    ]
  ]

end


to go
  ;;if ( not any? hares ) or ( not any? stags ) [ stop ]
  ;grow-stags-and-hares

  if ( ticks >= 50000 ) or ( not any? hunters ) [

    stop

  ]

  introduce-stags-and-hares
  ask hunters
  [
    if (target_type = STAG_TYPE) [ find-partner ]
    move
    hunt
    death
  ]
  move-stags-and-hares
  tick
end

to find-partner
  if not partnered? ;;Look for a partner only if the agent is not partnered at the moment
  [
    ;;Look nearby for hunters:
    let nearby-hunters []
    ifelse (selective_staghunter_cooperation?) [
      let unfiltered_hunters_around hunters-on neighbors
      set nearby-hunters unfiltered_hunters_around with [ target_type = STAG_TYPE ]
    ]
    [
      set nearby-hunters hunters-on neighbors
    ]
    ;;pick an unpartnered one if there was any nearby:
    if nearby-hunters != nobody [
      set partner one-of nearby-hunters with [ partnered? = false ]
      if partner != nobody [ ;;found a new partner!
        ask partner [ set partnered? true set leading? false set partner myself ] ;;Tell your new partner that you are hunting together
        set partnered? true ;;Agent is partnered now
        set leading? true ;;Agent is leading the hunt
        create-link-to partner ;;Create visible link with partner
        ask my-links [ set color green if highlight_partnership? [ set thickness 1 ] ]
      ]
    ]

  ]
end

to introduce-stags-and-hares
  if stag_introduction_counter <= 0 [
    set stag_introduction_counter stag_introduction_delay
    ;;Put a new stag on the field:
    if count stags < 100 [
    ask one-of patches with [ ( count turtles-here ) < 1 ] [
      sprout-stags 1 [ set size 2 set color red set ycor max-pycor ]
    ]
    ]
  ]

  if hare_introduction_counter <= 0 [
    set hare_introduction_counter hare_introduction_delay
    ;;Put a new hare on the field:
    ask one-of patches with [ ( count turtles-here ) < 1 ] [
      sprout-hares 1 [ set color yellow set ycor max-pycor ]
    ]
  ]
  set stag_introduction_counter stag_introduction_counter - 1
  set hare_introduction_counter hare_introduction_counter - 1
end

to end-partnership
  if partnered?
  [
    ask my-links [die] ;;Remove visible link with partner
    ask partner [ set partnered? false set leading? false set partner nobody move] ;;Tell your new partner that you are not hunting together anymore
    ;;Set agent free:
    set partnered? false
    set leading? false
    set partner nobody
    move ;;move away
  ]
end

to hunt

  ;; Look for stags and hares:
  ifelse ( count stags-here ) > 0 [ ;;Found a stag!
    ;; Check if agent is a stag hunter and is partnered with another stag hunter:
    if target_type = STAG_TYPE and partnered? [ ;;Is agent a stag hunter and is partnered with another hunter?
      ;; Is the partner another stag hunter?:
      let partner_type 0
      ask partner [ set partner_type target_type ]
      if partner_type = STAG_TYPE [ ;;Partner is also a stag hunter
        set energy energy + stags_payoff ;;Increase energy of agent by 2
        if energy > maximum_hunters_energy [ set energy maximum_hunters_energy ]
        ask partner [ set energy energy + stags_payoff if energy > maximum_hunters_energy [ set energy maximum_hunters_energy ] ] ;;Increase energy of partner by 2
        ;;Remove Stag from the patch:
        ask one-of stags-here [ die ]
        ;;End partnership with current partner:
        end-partnership
        ;;Put a new stag on the field:
        ;;;ask one-of patches with [ ( count turtles-here ) < 1 ] [
        ;;;  sprout-stags 1 [ set size 2 set color red]
        ;;;]
      ]
    ]
    ;;Both hunters should get separated ways from now on
  ]
  [
    if ( count hares-here ) > 0 [ ;;Found a hare!
      ;; Check if agent is a hare hunter and is partnered with another hare hunter:
      ifelse target_type = HARE_TYPE and partnered? [ ;;Is agent a hare hunter and is partnered with another hunter?
        ;; Is the partner another stag hunter?:
        let partner_type 0
        ask partner [ set partner_type target_type ]
        ifelse partner_type = HARE_TYPE [  ;;Partner is also a hare hunter
          set energy energy + hares_payoff ;;Increase energy of agent by 1
          if energy > maximum_hunters_energy [ set energy maximum_hunters_energy ]
          ask partner [ set energy energy + hares_payoff if energy > maximum_hunters_energy [ set energy maximum_hunters_energy ]] ;;Increase energy of partner by 1
          ;;Remove Hare from the patch:
          ask one-of hares-here [ die ]
          ;;End partnership with current partner:
          end-partnership
          ;;Put a new hare on the field:
          ;;;ask one-of patches with [ ( count turtles-here ) < 1 ] [
          ;;;  sprout-hares 1 [ set color yellow ]
          ;;;]
        ]
        [
          ;;Partner is not a hare hunter, thus only increase the energy of the hare hunter:
          set energy energy + hares_payoff ;;Increase energy of agent by 1
          if energy > maximum_hunters_energy [ set energy maximum_hunters_energy ]
          ;;Remove Hare from the patch:
          ask one-of hares-here [ die ]
          ;;End partnership with current partner:
          end-partnership
          ;;Put a new hare on the field:
          ;;;ask one-of patches with [ ( count turtles-here ) < 1 ] [
          ;;;  sprout-hares 1 [ set color yellow ]
          ;;;]
        ]
      ]
      [
        ;;Check if agent is a lonely hare hunter:
        if target_type = HARE_TYPE [
          set energy energy + hares_payoff ;;Increase energy of agent by 1
          if energy > maximum_hunters_energy [ set energy maximum_hunters_energy ]
          ;;Remove Hare from the patch:
          ask one-of hares-here [ die ]
          ;;End partnership with current partner:
          end-partnership
          ;;Put a new hare on the field:
          ;;;ask one-of patches with [ ( count turtles-here ) < 1 ] [
          ;;;  sprout-hares 1 [ set color yellow ]
          ;;;]
        ]
      ]
    ]
    ;;Both hunters should get separated ways from now on
  ]


end

to grow-stags-and-hares

  ask n-of stags_number patches with [ ( count turtles-here ) < 1 ] [
    sprout-stags 1 [ set size 2 set color red]
  ]
  ask n-of hares_number patches with [ ( count turtles-here ) < 1 ] [
    sprout-hares 1 [ set color yellow ]
  ]

end

to move

  ifelse partnered? and not leading? [
    let partner_xcor 0
    let partner_ycor 0
    ask partner [set partner_xcor xcor set partner_ycor ycor ]
    setxy ( partner_xcor + 1 ) partner_ycor
  ]
  [
    rt random 50
    lt random 50
    fd 1
  ]
  ;; moving takes some energy
  set energy energy - energy_decay_rate
end

to death
  ;; first of all check if it is time to reproduce:
  if (reproduction_enabled?)
  [
    ifelse ( time_to_reproduce = 0 ) [ ;and not reproduced? )[
      if (count hunters < 3000 ) [
        hatch 1 [ set energy starting_hunters_energy set time_to_reproduce hunters_reproduction_delay set partnered? false set leading? false set partner nobody move ]
        set reproduced? true
      ]
      set time_to_reproduce hunters_reproduction_delay
    ]
    [
      set time_to_reproduce time_to_reproduce - 1
    ]
  ]
  ;; die if you run out of energy
  if energy < 0 [
    if partner != nobody [ ;;check if agent is partnered
      ask partner [ set partnered? false set leading? false set partner nobody ] ;;Tell your partner that you are not hunting together anymore
    ]
    die
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
296
13
916
634
-1
-1
12.0
1
10
1
1
1
0
1
1
1
-25
25
-25
25
1
1
1
ticks
30.0

BUTTON
89
25
144
58
setup
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
154
25
209
58
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
923
13
1470
302
Populations
Time
Population
0.0
100.0
0.0
111.0
true
true
"set-plot-y-range 0 count hunters" ""
PENS
"stag hunters" 1.0 0 -2674135 true "" "plot count hunters with [target_type = STAG_TYPE]"
"hare hunters" 1.0 0 -1184463 true "" "plot count hunters with [target_type = HARE_TYPE]"

SLIDER
8
337
286
370
stags_hunters_number
stags_hunters_number
0
200
100.0
1
1
NIL
HORIZONTAL

SLIDER
9
522
288
555
energy_decay_rate
energy_decay_rate
0
0.3
0.07
0.01
1
NIL
HORIZONTAL

SLIDER
9
161
287
194
stags_number
stags_number
0
150
20.0
1
1
NIL
HORIZONTAL

SLIDER
9
195
287
228
hares_number
hares_number
0
150
20.0
1
1
NIL
HORIZONTAL

SWITCH
9
646
191
679
highlight_partnership?
highlight_partnership?
1
1
-1000

SLIDER
10
436
288
469
stags_payoff
stags_payoff
0
10
2.0
0.1
1
NIL
HORIZONTAL

SLIDER
9
476
287
509
hares_payoff
hares_payoff
0
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
8
376
286
409
hares_hunters_number
hares_hunters_number
0
200
100.0
1
1
NIL
HORIZONTAL

PLOT
924
314
1470
599
Ratio Stags hunters vs Hares hunters
Time
Percentage
0.0
100.0
0.0
100.0
true
true
"set-plot-y-range 0 100" ""
PENS
"Stags Hunters" 1.0 0 -8053223 true "" "plot  ( count  hunters with [ target_type = STAG_TYPE ] ) * 100 / count hunters"
"Hares Hunters" 1.0 0 -1184463 true "" "plot  ( count  hunters with [ target_type = HARE_TYPE ] ) * 100 / count hunters"

SLIDER
10
77
286
110
starting_hunters_energy
starting_hunters_energy
0
50
20.0
1
1
NIL
HORIZONTAL

SLIDER
10
112
286
145
maximum_hunters_energy
maximum_hunters_energy
0
500
20.0
1
1
NIL
HORIZONTAL

SLIDER
10
571
288
604
hunters_reproduction_delay
hunters_reproduction_delay
100
1000
150.0
50
1
NIL
HORIZONTAL

SWITCH
9
610
191
643
reproduction_enabled?
reproduction_enabled?
1
1
-1000

SLIDER
9
282
291
315
hare_introduction_delay
hare_introduction_delay
1
30
1.0
0.5
1
NIL
HORIZONTAL

SLIDER
9
246
288
279
stag_introduction_delay
stag_introduction_delay
1
30
1.0
0.5
1
NIL
HORIZONTAL

BUTTON
219
26
283
60
go-1
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
198
644
447
677
selective_staghunter_cooperation?
selective_staghunter_cooperation?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?


## HOW TO USE IT



## THINGS TO NOTICE


## THINGS TO TRY



## NETLOGO FEATURES



## RELATED MODELS



## HOW TO CITE



Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2001 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227.

<!-- 2001 -->
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

rabbit
false
0
Circle -7500403 true true 76 150 148
Polygon -7500403 true true 176 164 222 113 238 56 230 0 193 38 176 91
Polygon -7500403 true true 124 164 78 113 62 56 70 0 107 38 124 91

rabbit2
false
0
Polygon -7500403 true true 61 150 76 180 91 195 103 214 91 240 76 255 61 270 76 270 106 255 132 209 151 210 181 210 211 240 196 255 181 255 166 247 151 255 166 270 211 270 241 255 240 210 270 225 285 165 256 135 226 105 166 90 91 105
Polygon -7500403 true true 75 164 94 104 70 82 45 89 19 104 4 149 19 164 37 162 59 153
Polygon -7500403 true true 64 98 96 87 138 26 130 15 97 36 54 86
Polygon -7500403 true true 49 89 57 47 78 4 89 20 70 88
Circle -16777216 true false 37 103 16
Line -16777216 false 44 150 104 150
Line -16777216 false 39 158 84 175
Line -16777216 false 29 159 57 195
Polygon -5825686 true false 0 150 15 165 15 150
Polygon -5825686 true false 76 90 97 47 130 32
Line -16777216 false 180 210 165 180
Line -16777216 false 165 180 180 165
Line -16777216 false 180 165 225 165
Line -16777216 false 180 210 210 240

sheep 2
false
0
Polygon -7500403 true true 209 183 194 198 179 198 164 183 164 174 149 183 89 183 74 168 59 198 44 198 29 185 43 151 28 121 44 91 59 80 89 80 164 95 194 80 254 65 269 80 284 125 269 140 239 125 224 153 209 168
Rectangle -7500403 true true 180 195 195 225
Rectangle -7500403 true true 45 195 60 225
Rectangle -16777216 true false 180 225 195 240
Rectangle -16777216 true false 45 225 60 240
Polygon -7500403 true true 245 60 250 72 240 78 225 63 230 51
Polygon -7500403 true true 25 72 40 80 42 98 22 91
Line -16777216 false 270 137 251 122
Line -16777216 false 266 90 254 90

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment_1" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50000"/>
    <exitCondition>count (hunters) &lt; 1</exitCondition>
    <metric>count  hunters with [ target_type = STAG_TYPE ]</metric>
    <metric>count  hunters with [ target_type = HARE_TYPE ]</metric>
    <enumeratedValueSet variable="reproduction_enabled?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stags_number">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hares_number">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting_hunters_energy">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hares_hunters_number">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energy_decay_rate">
      <value value="0.02"/>
      <value value="0.03"/>
      <value value="0.04"/>
      <value value="0.05"/>
      <value value="0.06"/>
      <value value="0.07"/>
      <value value="0.08"/>
      <value value="0.09"/>
      <value value="0.1"/>
      <value value="0.11"/>
      <value value="0.12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum_hunters_energy">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stag_introduction_delay">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="highlight_partnership?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hare_introduction_delay">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunters_reproduction_delay">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stags_payoff">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hares_payoff">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stags_hunters_number">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
