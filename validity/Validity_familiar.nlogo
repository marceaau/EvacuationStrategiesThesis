__includes [ "astaralgorithm.nls" "astaralgorithm_original.nls" ]

globals [
  emergency?
  alarm?

  exits
  stairs
  stairs_strategy

  stair_width
  queue_radius_exit
  queue_radius_stair

  list_exit_queue
  list_stair_queue

  vp1_stairs1 vp1_stairs2 vp1_stairs3 vp1_stairs4 vp1_stairs5 vp1_list
  vp0_exit1 vp0_exit2 vp0_exit3 vp0_exit4 vp0_exit5 vp0_list

  vp0_exit1_up vp0_exit1_down vp0_exit2_up vp0_exit2_down vp0_exit3_up vp0_exit3_down vp0_exit4_up vp0_exit4_down vp0_exit5_up vp0_exit5_down
  vp0_down vp0_up

  Final-Cost

  stairs1_queue stairs2_queue stairs3_queue stairs4_queue stairs5_queue

  exit1_queue exit2_queue exit3_queue exit4_1_queue exit4_2_queue exit5_queue

  evac100 evac95 evac75 evac50
  delay_list
  mean_delay
  min_delay
  max_delay

  density_list
  density_patches
  mean_density
  walkspeed_list
  mean_walkspeed

  count_exit_1
  count_exit_2
  count_exit_3
  count_exit_4
  count_exit_5
]

patches-own[
  father
  Cost-path
  visited?
  active?
  exit
]

breed [ evacuees evacuee ]
breed [ staffs staff ]

evacuees-own[
  state
  walking-speed
  reaction-timer
  queue-timer
  familiar?
  compliant?
  got-help?
  phased-decision?
  current-floor
  destination
  destination_number
  path
  staff-member?
  delay-timer
]

staffs-own[
  walking-speed
  current-floor
  destination
  path
]

to setup
  ca
  reset-ticks
  utilities

  ifelse(wider-exits)
  [
    set exits (list patch 14 6 patch 14 7 patch 5 45 patch 6 45 patch 18 17 patch 18 18 patch 49 32 patch 50 32 patch 51 32 patch 51 45 patch 50 45 patch 49 45 patch 82 6 patch 82 5)
  ]
  [
    set exits (list patch 14 5 patch 14 6 patch 14 7 patch 14 8 patch 4 45 patch 5 45 patch 6 45 patch 7 45 patch 18 16 patch 18 17 patch 18 18 patch 18 19 patch 48 32 patch 49 32 patch 50 32 patch 51 32 patch 52 32 patch 52 45 patch 51 45 patch 50 45 patch 49 45 patch 48 45 patch 82 7 patch 82 6 patch 82 5 patch 82 4)
  ]

  ifelse(wider-stairs)
  [
    set stairs (list patch 4 48 patch 4 49 patch 4 50 patch 4 51 patch 10 72 patch 10 73 patch 10 74 patch 10 75 patch 41 62 patch 42 62 patch 43 62 patch 44 62 patch 64 78 patch 64 79 patch 64 80 patch 64 81 patch 78 55 patch 78 56 patch 78 57 patch 78 58)
  ]
  [
    set stairs (list patch 4 48 patch 4 49 patch 4 50 patch 10 73 patch 10 74 patch 10 75 patch 42 62 patch 43 62 patch 44 62 patch 64 78 patch 64 79 patch 64 80 patch 78 55 patch 78 56 patch 78 57)
  ]

  wider-exits-strategy
  wider-stairs-strategy
  obstacles-strategy
  one-way-traffic-strategy

  let number_exit 0
  let prev_exit patch 0 0
  let prev_stairs patch 0 0


  foreach exits [
    [x] ->
    ask x
    [
      if(pxcor != [pxcor] of prev_exit and pycor != [pycor] of prev_exit)
      [
        set number_exit (number_exit + 1)
      ]

      ask patches with [pcolor = white and pycor < 45] in-radius queue_radius_exit[
        set pcolor 7.8
        set exit number_exit
      ]
      set exit number_exit
    ]
    set prev_exit x
  ]

  set number_exit 0

  foreach stairs [
    [x] ->
    ask x
    [
      if(pxcor != [pxcor] of prev_stairs and pycor != [pycor] of prev_stairs)
      [
        set number_exit (number_exit + 1)
      ]

      ask patches with [pcolor = white] in-radius queue_radius_stair[
        set pcolor 8.8
        set exit number_exit
      ]
      set exit number_exit
    ]

    set prev_stairs x
  ]

  ask patches with [pcolor = 8.8 and pycor < 76 and pycor > 70 and pxcor > 57 and pxcor < 68] [ set pcolor white]

  ask patch 64 75  [ set pcolor white ]
  ask patch 68 75  [ set pcolor white ]
  ask patch 68 74  [ set pcolor white ]
  ask patch 69 75  [ set pcolor white ]
  ask patches with [pycor >= 13 and pycor <= 19 and pxcor = 13] [ set pcolor white ]
  ask patches with [pycor >= 78 and pycor <= 80 and pxcor = 69] [ set pcolor white ]
  ask patches with [pycor >= 29 and pycor <= 31 and pxcor = 56] [ set pcolor white ]
  ask patches with [pycor >= 52 and pycor <= 60 and (pxcor = 73 or pxcor = 72)] [ set pcolor white ]
  ask patches with [pxcor >= 42 and pxcor <= 44 and pycor = 56] [ set pcolor white ]

  set exits patches with [pcolor = blue]
  set stairs stairs_strategy

  ; including queue radius
  set list_exit_queue patches with [pcolor = 7.8]
  set list_stair_queue patches with [pcolor = 8.8]

  set vp1_stairs1 patches with [(pcolor = white or pcolor = yellow or pcolor = blue or exit = 1) and pycor > 45]
  set vp1_stairs2 patches with [(pcolor = white or pcolor = yellow or pcolor = blue or exit = 2) and pycor > 45]
  set vp1_stairs3 patches with [(pcolor = white or pcolor = yellow or pcolor = blue or exit = 3) and pycor > 45]
  set vp1_stairs4 patches with [(pcolor = white or pcolor = yellow or pcolor = blue or exit = 4) and pycor > 45]
  set vp1_stairs5 patches with [(pcolor = white or pcolor = yellow or pcolor = blue or exit = 5) and pycor > 45]
  set vp1_list (list vp1_stairs1 vp1_stairs2 vp1_stairs3 vp1_stairs4 vp1_stairs5)

  set vp0_exit1 patches with [(pcolor = white or pcolor = yellow or pcolor = blue or exit = 1) and pycor < 45]
  set vp0_exit2 patches with [(pcolor = white or pcolor = yellow or pcolor = blue or exit = 2) and pycor < 45]
  set vp0_exit3 patches with [(pcolor = white or pcolor = yellow or pcolor = blue or exit = 3) and pycor < 45]
  set vp0_exit4 patches with [(pcolor = white or pcolor = yellow or pcolor = blue or exit = 4) and pycor < 45]
  set vp0_exit5 patches with [(pcolor = white or pcolor = yellow or pcolor = blue or exit = 5) and pycor < 45]
  set vp0_list (list vp0_exit1 vp0_exit2 vp0_exit3 vp0_exit4 vp0_exit5)

  set vp0_exit1_up patches with [(pcolor = white or pcolor = yellow or pcolor = blue or pcolor = red or exit = 1) and pycor < 45]
  set vp0_exit1_down patches with [(pcolor = white or pcolor = yellow or pcolor = blue or pcolor = pink or exit = 1) and pycor < 45]
  set vp0_exit2_up patches with [(pcolor = white or pcolor = yellow or pcolor = blue or pcolor = red or exit = 2) and pycor < 45]
  set vp0_exit2_down patches with [(pcolor = white or pcolor = yellow or pcolor = blue or pcolor = pink or exit = 2) and pycor < 45]
  set vp0_exit3_up patches with [(pcolor = white or pcolor = yellow or pcolor = blue or pcolor = red or exit = 3) and pycor < 45]
  set vp0_exit3_down patches with [(pcolor = white or pcolor = yellow or pcolor = blue or pcolor = pink or exit = 3) and pycor < 45]
  set vp0_exit4_up patches with [(pcolor = white or pcolor = yellow or pcolor = blue or pcolor = red or exit = 4) and pycor < 45]
  set vp0_exit4_down patches with [(pcolor = white or pcolor = yellow or pcolor = blue or pcolor = pink or exit = 4) and pycor < 45]
  set vp0_exit5_up patches with [(pcolor = white or pcolor = yellow or pcolor = blue or pcolor = red or exit = 5) and pycor < 45]
  set vp0_exit5_down patches with [(pcolor = white or pcolor = yellow or pcolor = blue or pcolor = pink or exit = 5) and pycor < 45]

  set vp0_up (list vp0_exit1_up vp0_exit2_up vp0_exit3_up vp0_exit4_up vp0_exit5_up)
  set vp0_down (list vp0_exit1_down vp0_exit2_down vp0_exit3_down vp0_exit4_down vp0_exit5_down)

  set stairs1_queue []
  set stairs2_queue []
  set stairs3_queue []
  set stairs4_queue []
  set stairs5_queue []

  set exit1_queue []
  set exit2_queue []
  set exit3_queue []
  set exit4_1_queue []
  set exit4_2_queue []
  set exit5_queue []

  create-evacuees population [
    move-to one-of patches with [pcolor = white]
    set size 1.5
    set color red

    set state 0
    set walking-speed 1
    set current-floor ifelse-value (ycor > 45) [1] [0]
    set reaction-timer random 15
    set familiar? ifelse-value(random-float 1 < familiarity) [true] [false]
    set compliant? ifelse-value(random-float 1 < compliance) [true] [false]
    set staff-member? false
    set got-help? false
    set phased-decision? false

    set color ifelse-value(familiar?) [blue] [red]

    ifelse(current-floor = 1)
    [
      ifelse(familiar?)
      [
        set destination min-one-of (list_stair_queue with [pycor > 45]) [distance myself]

        if(xcor >= 18 and xcor <= 49 and ycor >= 55 and ycor <= 71)
        [
          set destination one-of list_stair_queue with [exit = 3]
        ]
      ]
      [
        set destination one-of list_stair_queue with [exit = 4]
      ]
    ]
    [
      ifelse(familiar?)
      [
        set destination min-one-of (list_exit_queue with [pycor < 45]) [distance myself]

        if(xcor >= 0 and xcor <= 14 and ycor >= 0 and ycor <= 28)
        [
          set destination min-one-of list_exit_queue with [exit = 1 or exit = 2] [distance myself]
        ]
      ]
      [
        set destination one-of list_exit_queue with [exit = 4]
      ]
    ]

    set destination_number [exit] of destination

    if(phased-evacuation)
    [
      ifelse(current-floor = 1)
      [
        ; gedeelte hoofd trap
        if(xcor >= 55 and xcor <= 71 and ycor >= 62 and pycor <= 89)
        [
          set reaction-timer reaction-timer + 0
        ]
        if(xcor > 71 and xcor <= 82 and ycor >= 71 and pycor <= 89)
        [
          set reaction-timer reaction-timer + 15
        ]
        if(xcor >= 16 and xcor < 55 and ycor >= 76 and pycor <= 89)
        [
          set reaction-timer reaction-timer + 30
        ]
        if(xcor >= 16 and xcor < 55 and ycor >= 53 and pycor <= 76)
        [
          set reaction-timer reaction-timer + 45
        ]
        if(xcor >= 0 and xcor < 16 and ycor >= 45 and pycor <= 89)
        [
          set reaction-timer reaction-timer + 0
        ]
      ]
      [
      ]
    ]
  ]

  evacuee-staff-strategy
  dynamic-signs-strategy

  set evac100 0
  set evac95 0
  set evac75 0
  set evac50 0
  set delay_list []
  set mean_delay 0
  set density_list []
  set density_patches ((count list_stair_queue) + (count list_exit_queue))
  set walkspeed_list []


end

to go

  if(count evacuees = 0 and count staffs = 0)
  [
    set evac100 ticks
    set mean_delay mean delay_list
    set min_delay min delay_list
    set max_delay max delay_list
    set mean_density mean density_list
    set mean_walkspeed mean walkspeed_list

    stop
  ]

  if(evac95 < 1 and ((count evacuees) / population <= 0.05))
  [
    set evac95 ticks
  ]
  if(evac75 < 1 and ((count evacuees) / population <= 0.25))
  [
    set evac75 ticks
  ]
  if(evac50 < 1 and ((count evacuees) / population <= 0.5))
  [
    set evac50 ticks
  ]


  ask evacuees[
    (ifelse
      state = 0
      [
        process-state-investigating
      ]
      state = 1
      [
        process-receive-help-staff-member
        process-signs
        process-state-evacuating

        set walkspeed_list fput walking-speed walkspeed_list
      ]
      state = 2
      [
        process-state-exit-queue

        set walkspeed_list fput walking-speed walkspeed_list
      ]
      state = 3
      [
        process-state-on-stairs
      ]
      state = 4
      [
        process-state-stairs-queue

        set walkspeed_list fput walking-speed walkspeed_list
      ]
      state = 5
      [
        process-walk-staff-member
      ]
      state = 6
      [
        process-help-staff-member
      ]
     )
  ]

  clear-queues

  set density_list fput ((count evacuees-on list_stair_queue + count evacuees-on list_exit_queue) / density_patches) density_list

  tick
end

to social-force
  let people-present (count evacuees in-cone 3 60)
  set people-present people-present - 1

  (ifelse
    people-present = 1
    [
      set walking-speed 0.8
    ]
    people-present = 2
    [
      set walking-speed 0.7
    ]
    people-present > 2 and people-present <= 5
    [
      set walking-speed 0.55
    ]
    people-present > 5 and people-present <= 7
    [
      set walking-speed 0.35
    ]
    people-present > 7
    [
      set walking-speed 0.1
    ]
    ;else
    [
      set walking-speed 1
    ]
  )
end

to process-state-investigating
  ifelse(reaction-timer > 0)
  [
    set reaction-timer reaction-timer - 1
  ]
  [
    set state 1
    calculate-path
  ]
end

to process-state-evacuating
  ifelse(distance destination < walking-speed or ([exit] of patch-here = destination_number))
  [
    let nr destination_number

    ifelse(current-floor = 1)
    [
      move-to min-one-of patches with [pcolor = 8.8] [distance myself]
      set destination one-of stairs with [exit = nr]
      set state 4
      calculate-path-stairs-queue
    ]
    [
      move-to min-one-of patches with [pcolor = 7.8] [distance myself]
      set destination one-of exits with [exit = nr]
      set state 2
      calculate-path-exit-queue
    ]
  ]
  [
    ifelse(not empty? path)
    [
      face first path
      social-force
      fd walking-speed

      if distance first path < walking-speed [
        set path remove-item 0 path
      ]
    ]
    [
      face destination
      fd walking-speed
    ]
  ]
end

to process-state-exit-queue
  face destination
  social-force

  ifelse(distance destination < walking-speed)
  [
    if(destination_number = 1) [ set exit1_queue fput self exit1_queue ]
    if(destination_number = 2) [ set exit2_queue fput self exit2_queue ]
    if(destination_number = 3) [ set exit3_queue fput self exit3_queue ]

    if(destination_number = 4)
    [
      ifelse(ycor > 38) [ set exit4_1_queue fput self exit4_1_queue ] [ set exit4_2_queue fput self exit4_2_queue ]
    ]

    if(destination_number = 5) [ set exit5_queue fput self exit5_queue ]

    set state "queue"
  ]
  [
    let count-ahead count evacuees in-cone 2 10

    if(count-ahead > 3)
    [
      let patch-right patch-right-and-ahead 90 1
      let patch-left patch-left-and-ahead 90 1

      ifelse(patch-left != nobody and [pcolor] of patch-left != black)
      [
        ;links vrij

        ifelse(patch-right != nobody and [pcolor] of patch-right != black)
        [
          let count-right count evacuees-on patch-left
          let count-left count evacuees-on patch-right

          ;links vrij rechts vrij
          (
            ifelse
            count-right > count-left
            [
              ; rechts drukker dan links
              left 90

            ]
            count-right < count-left
            [
              ; links drukker dan rechts
              right 90
            ]
            [
              ; even druk
              ifelse random 100 < 50 [ left 90 ] [ right 90 ]
            ]
           )
        ]
        [
          left 90
        ]


      ]
      [
        ; rechtsvrij
        right 90
      ]

      fd 0.5
      set destination min-one-of exits [distance myself]
      calculate-path-exit-queue
    ]

    ifelse(not empty? path)
    [
      face first path
      social-force
      fd walking-speed

      if distance first path < walking-speed [
        set path remove-item 0 path
      ]
    ]
    [
      face destination
      fd walking-speed
    ]
  ]

  set delay-timer (delay-timer + 1)

end

to process-state-on-stairs
  ifelse(queue-timer > 0)
  [
    set queue-timer queue-timer - 1
  ]
  [
    set current-floor 0
    set state 1
    set got-help? false
    move-to patch (xcor) (ycor - 45)

    ifelse(familiar?)
    [
      let nr destination_number
      set destination one-of (list_exit_queue with [exit = nr])
      ;set destination min-one-of (list_exit_queue with [pycor < 45]) [distance myself]
    ]
    [
      set destination one-of list_exit_queue with [exit = 4]
    ]

    set destination_number [exit] of destination
    calculate-path
  ]
end

to process-state-stairs-queue
  face destination
  social-force

  ifelse(distance destination < walking-speed)
  [
    if(destination_number = 1) [ set stairs1_queue fput self stairs1_queue ]
    if(destination_number = 2) [ set stairs2_queue fput self stairs2_queue ]
    if(destination_number = 3) [ set stairs3_queue fput self stairs3_queue ]
    if(destination_number = 4) [ set stairs4_queue fput self stairs4_queue ]
    if(destination_number = 5) [ set stairs5_queue fput self stairs5_queue ]

    set state "queue"
  ]
  [
    let count-ahead count evacuees in-cone 2 10

    if(count-ahead > 3)
    [
      let patch-right patch-right-and-ahead 90 1
      let patch-left patch-left-and-ahead 90 1

      ifelse(patch-left != nobody and [pcolor] of patch-left != black)
      [
        ;links vrij

        ifelse(patch-right != nobody and [pcolor] of patch-right != black)
        [
          let count-right count evacuees-on patch-left
          let count-left count evacuees-on patch-right

          ;links vrij rechts vrij
          (
            ifelse
            count-right > count-left
            [
              ; rechts drukker dan links
              left 90

            ]
            count-right < count-left
            [
              ; links drukker dan rechts
              right 90
            ]
            [
              ; even druk
              ifelse random 100 < 50 [ left 90 ] [ right 90 ]
            ]
           )
        ]
        [
          left 90
        ]


      ]
      [
        ; rechtsvrij
        right 90
      ]

      fd 0.5
      set destination min-one-of stairs [distance myself]
      calculate-path-stairs-queue
    ]

    ifelse(not empty? path)
    [
      face first path
      social-force
      fd walking-speed

      if distance first path < walking-speed [
        set path remove-item 0 path
      ]
    ]
    [
      face destination
      fd walking-speed
    ]
  ]

  set delay-timer (delay-timer + 1)

end

to process-walk-staff-member
  ifelse(distance destination < walking-speed)
  [
   ifelse(current-floor = 1)
   [
      move-to destination
      set state 6
   ]
   [
      move-to destination
      set state 6
   ]
  ]
  [
    ifelse(not empty? path)
    [
      face first path
      social-force
      fd walking-speed

      if distance first path < walking-speed [
        set path remove-item 0 path
      ]
    ]
    [
      face destination
      fd walking-speed
    ]
  ]
end

to process-help-staff-member
  if(count(evacuees) / population < 0.1)
  [
    set state 1
    ifelse(current-floor = 1)
    [
      set destination min-one-of (list_stair_queue with [pycor > 45]) [distance myself]
    ]
    [
      set destination min-one-of (list_exit_queue with [pycor < 45]) [distance myself]
    ]
    set destination_number [exit] of destination
    calculate-path
  ]
end

to process-receive-help-staff-member
  if(evacuee-staff and not got-help? and compliant?)
  [
    if any? evacuees with [staff-member?] in-cone sight vision
    [
      ifelse(current-floor = 1)
      [
        set destination min-one-of list_stair_queue [distance myself]

        if(xcor >= 19 and xcor <= 46 and ycor >= 57 and ycor <= 71) [ set destination one-of list_stair_queue with [exit = 3] ]
        if(xcor >= 0 and xcor <= 13 and ycor >= 46 and ycor <= 75) [ set destination one-of list_stair_queue with [exit = 2 or exit = 1] ]
        if(xcor >= 0 and xcor <= 30 and ycor > 75  and ycor <= 90) [ set destination one-of list_stair_queue with [exit = 2] ]
        if(xcor >= 71 and xcor <= 82 and ycor >= 47 and ycor <= 89) [ set destination one-of list_stair_queue with [exit = 5] ]

        set destination_number [exit] of destination
        calculate-path
      ]
      [
        set destination min-one-of list_exit_queue [distance myself]

        if(xcor >= 19 and xcor <= 46 and ycor >= 12 and ycor <= 26) [ set destination one-of list_exit_queue with [exit = 3] ]
        if(xcor >= 0 and xcor <= 13 and ycor >= 1 and ycor <= 30) [ set destination one-of list_exit_queue with [exit = 2 or exit = 1] ]
        if(xcor >= 0 and xcor <= 30 and ycor > 30  and ycor <= 45) [ set destination one-of list_exit_queue with [exit = 2] ]
        if(xcor >= 71 and xcor <= 82 and ycor >= 2 and ycor <= 44) [ set destination one-of list_exit_queue with [exit = 5] ]

        set destination_number [exit] of destination
        calculate-path
      ]

      set got-help? true
    ]
  ]
end

to process-signs

  if(dynamic-signs and not got-help? and compliant?)
  [
    if any? patches with [pcolor = cyan] in-cone sight vision
    [
      ifelse(current-floor = 1)
      [
        set destination min-one-of (list_stair_queue with [pycor > 45]) [distance myself]

        if(xcor >= 19 and xcor <= 46 and ycor >= 57 and ycor <= 71) [ set destination one-of list_stair_queue with [exit = 3] ]
        if(xcor >= 0 and xcor <= 13 and ycor >= 46 and ycor <= 75) [ set destination one-of list_stair_queue with [exit = 2 or exit = 1] ]
        if(xcor >= 0 and xcor <= 30 and ycor > 75  and ycor <= 90) [ set destination one-of list_stair_queue with [exit = 2] ]
        if(xcor >= 71 and xcor <= 82 and ycor >= 47 and ycor <= 89) [ set destination one-of list_stair_queue with [exit = 5] ]

        set destination_number [exit] of destination
        calculate-path
      ]
      [

        set destination min-one-of (list_exit_queue with [pycor < 45]) [distance myself]

        if(xcor >= 19 and xcor <= 46 and ycor >= 12 and ycor <= 26) [ set destination one-of list_exit_queue with [exit = 3] ]
        if(xcor >= 0 and xcor <= 13 and ycor >= 1 and ycor <= 30) [ set destination one-of list_exit_queue with [exit = 2 or exit = 1] ]
        if(xcor >= 0 and xcor <= 30 and ycor > 30  and ycor <= 45) [ set destination one-of list_exit_queue with [exit = 2] ]
        if(xcor >= 71 and xcor <= 82 and ycor >= 2 and ycor <= 44) [ set destination one-of list_exit_queue with [exit = 5] ]

        set destination_number [exit] of destination
        calculate-path
      ]

      set got-help? true
    ]
  ]


end

to clear-queues
  set stairs1_queue process-queue-stairs stairs1_queue
  set stairs2_queue process-queue-stairs stairs2_queue
  set stairs3_queue process-queue-stairs stairs3_queue
  set stairs4_queue process-queue-stairs stairs4_queue
  set stairs5_queue process-queue-stairs stairs5_queue


  ifelse(wider-exits)
  [
    set exit1_queue process-queue-exits exit1_queue 3
    set exit2_queue process-queue-exits exit2_queue 3
    set exit3_queue process-queue-exits exit3_queue 3
    set exit4_1_queue process-queue-exits exit4_1_queue 5
    set exit4_2_queue process-queue-exits exit4_2_queue 5
    set exit5_queue process-queue-exits exit5_queue 3
  ]
  [
    set exit1_queue process-queue-exits exit1_queue 1
    set exit2_queue process-queue-exits exit2_queue 1
    set exit3_queue process-queue-exits exit3_queue 1
    set exit4_1_queue process-queue-exits exit4_1_queue 3
    set exit4_2_queue process-queue-exits exit4_2_queue 3
    set exit5_queue process-queue-exits exit5_queue 1
  ]
end

to-report process-queue-stairs [#queue]
  ifelse length #queue > (stair_width)
  [
    repeat stair_width
    [
      ask first #queue
      [
        if(destination_number = 1) [ move-to patch 1 48 ]
        if(destination_number = 2) [ move-to patch 13 73 ]
        if(destination_number = 3) [ move-to patch 44 59 ]
        if(destination_number = 4) [ move-to patch 67 79 ]
        if(destination_number = 5) [ move-to patch 81 55 ]

        set #queue remove-item 0 #queue
        set state 3

        ifelse(wider-stairs) [ set queue-timer (6 + random 6) ] [ set queue-timer (9 + random 9) ]

        set delay_list fput delay-timer delay_list
        set delay-timer 0
      ]
    ]
  ]
  [
    repeat length #queue
    [
      ask first #queue
      [
        if(destination_number = 1) [ move-to patch 1 48 ]
        if(destination_number = 2) [ move-to patch 13 73 ]
        if(destination_number = 3) [ move-to patch 44 59 ]
        if(destination_number = 4) [ move-to patch 67 79 ]
        if(destination_number = 5) [ move-to patch 81 55 ]

        set #queue remove-item 0 #queue
        set state 3
        ifelse(wider-stairs) [ set queue-timer (6 + random 6) ] [ set queue-timer (9 + random 9) ]
        set delay_list fput delay-timer delay_list
        set delay-timer 0
      ]
    ]
  ]

  report #queue
end

to-report process-queue-exits [#queue #exit_width]
  ifelse length #queue > #exit_width
  [
    repeat #exit_width
    [
      ask first #queue
      [
        set #queue remove-item 0 #queue
        set delay_list fput delay-timer delay_list
        set delay-timer 0

        let nr destination_number
        (ifelse
          nr = 1 [ set count_exit_1 count_exit_1 + 1 ]
          nr = 2 [ set count_exit_2 count_exit_2 + 1 ]
          nr = 3 [ set count_exit_3 count_exit_3 + 1 ]
          nr = 4 [ set count_exit_4 count_exit_4 + 1 ]
          nr = 5 [ set count_exit_5 count_exit_5 + 1 ]
          )
        die
      ]
    ]
  ]
  [
    repeat length #queue
    [
      ask first #queue
      [
        set #queue remove-item 0 #queue
        set delay_list fput delay-timer delay_list
        set delay-timer 0

        let nr destination_number
        (ifelse
          nr = 1 [ set count_exit_1 count_exit_1 + 1 ]
          nr = 2 [ set count_exit_2 count_exit_2 + 1 ]
          nr = 3 [ set count_exit_3 count_exit_3 + 1 ]
          nr = 4 [ set count_exit_4 count_exit_4 + 1 ]
          nr = 5 [ set count_exit_5 count_exit_5 + 1 ]
          )
        die
      ]
    ]
  ]

  report #queue
end

to wider-exits-strategy
  ; Wider exits strategy
  ifelse(wider-exits)
  [
    set queue_radius_exit (_start-queue-radius + 1)
    if(obstacles) [ set queue_radius_exit queue_radius_exit + 1 ]
    ask (patch-set patch 14 5 patch 14 8 patch 4 45 patch 7 45 patch 18 16 patch 18 19 patch 48 32 patch 52 32 patch 48 45 patch 52 45 patch 82 7 patch 82 4)
    [
      set pcolor blue
    ]
  ]
  [
    set queue_radius_exit (_start-queue-radius)
    if(obstacles) [ set queue_radius_exit _start-queue-radius + 1 ]
  ]
end

to wider-stairs-strategy
  ; Wider stairs strategy
  ifelse(wider-stairs)
  [
    set stair_width 5
    set queue_radius_stair (_start-queue-radius + 1)
    if(obstacles) [ set queue_radius_stair queue_radius_stair + 1 ]
    set stairs_strategy (patch-set patch 4 48 patch 4 49 patch 4 50 patch 4 51 patch 10 72 patch 10 73 patch 10 74 patch 10 75 patch 41 62 patch 42 62 patch 43 62 patch 44 62 patch 64 78 patch 64 79 patch 64 80 patch 64 81 patch 78 55 patch 78 56 patch 78 57 patch 78 58)

    ask (patch-set patch 1 51 patch 2 51 patch 3 51 patch 4 51 patch 10 72 patch 11 72 patch 12 72 patch 13 72 patch 41 62 patch 41 61 patch 41 60 patch 41 59 patch 64 81 patch 65 81 patch 66 81 patch 67 81 patch 78 58 patch 79 58 patch 80 58 patch 81 58)
    [
      set pcolor yellow
    ]

    ask (patch-set patch 1 52 patch 2 52 patch 3 52 patch 4 52 patch 10 71 patch 11 71 patch 12 71 patch 13 71 patch 40 62 patch 40 61 patch 40 60 patch 40 59 patch 40 58 patch 64 82 patch 65 82 patch 66 82 patch 67 82 patch 68 82 patch 78 59 patch 79 59 patch 80 59 patch 81 59)
    [
      set pcolor black
    ]
  ]
  [
    set stair_width 3
    set queue_radius_stair (_start-queue-radius)
    if(obstacles) [ set queue_radius_stair queue_radius_stair + 1 ]

    set stairs_strategy (patch-set patch 4 48 patch 4 49 patch 4 50 patch 10 73 patch 10 74 patch 10 75 patch 42 62 patch 43 62 patch 44 62 patch 64 78 patch 64 79 patch 64 80 patch 78 55 patch 78 56 patch 78 57)
  ]

end

to obstacles-strategy
  if(obstacles)
  [
    let patch_obstacles (patch-set patch 61 78 patch 62 82 patch 49 35 patch 52 34 patch 51 41 patch 49 41)
    ask patch_obstacles
    [
      set pcolor black
    ]
  ]
end

to one-way-traffic-strategy
  if(one-way-traffic)
  [
    ask patches with [pxcor >=  44 and pxcor <= 56 and pycor <= 40 and pycor >= 39 and pcolor = white]
    [
      set pcolor red
    ]

    ask patches with [pxcor >=  44 and pxcor <= 56 and pycor >= 37 and pycor <= 38 and pcolor = white]
    [
      set pcolor pink
    ]

    ask patches with [pxcor >=  6 and pxcor <= 18 and pycor >= 36 and pycor <= 37 and pcolor = white]
    [
      set pcolor red
    ]

    ask patches with [pxcor >=  8 and pxcor <= 18 and pycor >= 32 and pycor <= 35 and pcolor = white]
    [
      set pcolor pink
    ]

    ask patches with [pxcor >=  67 and pxcor <= 73 and pycor >= 32 and pycor <= 39 and pcolor = white]
    [
      set pcolor pink
    ]

    ask patches with [pxcor >=  67 and pxcor <= 75 and pycor >= 32 and pycor <= 41 and pcolor = white]
    [
      set pcolor red
    ]

  ]
end

to evacuee-staff-strategy

  if(evacuee-staff)
  [
    foreach [1 2 3 4 5 6]
    [
      [x] ->
      ask evacuee x
      [
        set color blue
        set state 5
        set staff-member? true

        ifelse(remainder x 2 = 0)
        [
          move-to one-of vp1_stairs1 with [pcolor = white]
        ]
        [
          move-to one-of vp0_exit1 with [pcolor = white]
        ]
      ]
    ]

    evacuee-staff-strategy-destination
  ]
end

to evacuee-staff-strategy-destination

  let list_staff_positions_top (list patch 23 78 patch 41 74 patch 74 77)
  let list_staff_positions_bottom (list patch 23 33 patch 41 29 patch 74 32)

  ask evacuees with [staff-member? and ycor > 45]
  [
    set destination min-one-of (patch-set list_staff_positions_top) [distance myself]
    set list_staff_positions_top remove destination list_staff_positions_top
    set current-floor 1
    set destination_number 1

    calculate-path
  ]

  ask evacuees with [staff-member? and ycor < 45]
  [
    set destination min-one-of (patch-set list_staff_positions_bottom) [distance myself]
    set list_staff_positions_bottom remove destination list_staff_positions_bottom
    set current-floor 0
    set destination_number 1

    calculate-path
  ]

end

to dynamic-signs-strategy
  if(dynamic-signs)
  [
    ask (patch-set patch 4 61 patch 10 61 patch 40 72 patch 22 82 patch 75 83 patch 77 71 patch 39 82)
    [
      set pcolor cyan
    ]

    ask (patch-set patch 4 16 patch 10 16 patch 40 27 patch 22 34 patch 75 38 patch 77 26 patch 39 37)
    [
      set pcolor cyan
    ]
  ]
end

to calculate-path
  reset-timer
 let Start patch-here
 if [pcolor] of patch-here = black
 [
    ifelse(any? ([neighbors] of patch-here) with [pcolor = white])
    [
      set Start one-of ([neighbors] of patch-here) with [pcolor = white]
    ]
    [
      die
    ]
 ]

  let calculated-path 0

 ifelse(current-floor = 1)
  [
    set calculated-path A* Start destination item (destination_number - 1) vp1_list
  ]
  [
    ifelse(one-way-traffic)
    [
      ifelse(xcor < [pxcor] of destination)
      [
        ;down
        set calculated-path A* Start destination item (destination_number - 1) vp0_down
      ]
      [
        ;up
        set calculated-path A* Start destination item (destination_number - 1) vp0_up
      ]
    ]
    [
      set calculated-path A* Start destination item (destination_number - 1) vp0_list
    ]
  ]

 if calculated-path != false [
  set path calculated-path
 ]

end

to calculate-path-exit-queue

 let Start patch-here
 if [pcolor] of patch-here = black
 [
    ifelse one-of ([neighbors] of patch-here) with [pcolor = 7.8 or pcolor = white] != nobody
    [
      move-to one-of ([neighbors] of patch-here) with [pcolor = 7.8 or pcolor = white]
      set Start patch-here
    ]
    [
      die
    ]
 ]

  let calculated-path 0
  set calculated-path A*_queue Start destination patches with [pcolor = blue or pcolor = 7.8]


 if calculated-path != false [
  set path calculated-path
 ]

end

to calculate-path-stairs-queue

 let Start patch-here
 if [pcolor] of patch-here = black
 [
    ifelse one-of ([neighbors] of patch-here) with [pcolor = 8.8 or pcolor = white] != nobody
    [
      move-to one-of ([neighbors] of patch-here) with [pcolor = 8.8 or pcolor = white]
      set Start patch-here
    ]
    [
      die
    ]
 ]

  let calculated-path 0
  set calculated-path A*_queue Start destination patches with [pcolor = yellow or pcolor = 8.8]


 if calculated-path != false [
  set path calculated-path
 ]

end

to utilities
  import-pcolors "tbm_compleet.png"

  ;define colors
  ask patches with [pcolor > 99 and pcolor < 105] [set pcolor blue]
  ask patches with [pcolor = 44.9] [set pcolor yellow]
  ask patches with [pcolor > 1.8 and pcolor < 2.5 or pcolor = 41 or pcolor = 2.9] [ set pcolor black ]
  ask patches with [pcolor = 6.4 or pcolor = 9.4] [ set pcolor white ]
  ask patches
  [
    set father nobody
    set Cost-path 0
    set visited? false
    set active? false
  ]

end

to-report evactimes
  report (list evac100 evac95 evac75 evac50)
end

to-report densities
  report (list mean_delay min_delay max_delay mean_density mean_walkspeed)
end

to-report evacuees_per_exit
  report (list count_exit_1 count_exit_2 count_exit_3 count_exit_4 count_exit_5)
end
@#$#@#$#@
GRAPHICS-WINDOW
212
11
884
748
-1
-1
8.0
1
10
1
1
1
0
0
0
1
0
82
0
90
0
0
1
ticks
30.0

BUTTON
10
10
73
43
NIL
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
76
10
139
43
NIL
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

BUTTON
143
10
206
43
NIL
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

SLIDER
8
47
206
80
population
population
0
2200
10.0
1
1
NIL
HORIZONTAL

INPUTBOX
8
86
109
146
_start-queue-radius
4.0
1
0
Number

SLIDER
8
156
180
189
familiarity
familiarity
0
1
0.8
0.01
1
NIL
HORIZONTAL

SLIDER
9
197
181
230
compliance
compliance
0
1
0.6
0.01
1
NIL
HORIZONTAL

SWITCH
11
323
128
356
wider-exits
wider-exits
1
1
-1000

SWITCH
12
361
132
394
wider-stairs
wider-stairs
1
1
-1000

SWITCH
12
400
120
433
obstacles
obstacles
1
1
-1000

SWITCH
13
438
155
471
one-way-traffic
one-way-traffic
1
1
-1000

SWITCH
14
512
147
545
dynamic-signs
dynamic-signs
1
1
-1000

SWITCH
13
475
175
508
phased-evacuation
phased-evacuation
1
1
-1000

SWITCH
14
548
148
581
evacuee-staff
evacuee-staff
1
1
-1000

SLIDER
9
234
181
267
sight
sight
0
10
6.0
0.5
1
NIL
HORIZONTAL

SLIDER
10
271
182
304
vision
vision
0
180
60.0
1
1
NIL
HORIZONTAL

MONITOR
897
14
974
59
Evac 100%
evac100
0
1
11

MONITOR
978
14
1048
59
Evac 95%
evac95
0
1
11

MONITOR
1052
14
1122
59
Evac 75%
evac75
0
1
11

MONITOR
1127
14
1197
59
Evac 50%
evac50
0
1
11

MONITOR
898
67
1001
112
Mean delay time
mean_delay
2
1
11

MONITOR
1009
67
1105
112
Max delay time
max_delay
0
1
11

MONITOR
1112
67
1204
112
Min delay time
min_delay
0
1
11

MONITOR
899
116
986
161
Mean density
mean_density
6
1
11

PLOT
899
167
1099
317
Evacuated
Time
People in the building
0.0
300.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

MONITOR
993
118
1101
163
Mean walk speed
mean_walkspeed
4
1
11

MONITOR
900
324
960
369
Nr exit 1
count_exit_1
0
1
11

MONITOR
970
325
1030
370
Nr exit 2
count_exit_2
0
1
11

MONITOR
1041
331
1098
376
Nr exit3
count_exit_3
17
1
11

MONITOR
899
377
959
422
Nr exit 4
count_exit_4
0
1
11

MONITOR
969
377
1029
422
Nr exit 5
count_exit_5
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="BaseCase" repetitions="60" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>evac100</metric>
    <enumeratedValueSet variable="population">
      <value value="1200"/>
      <value value="1600"/>
      <value value="2000"/>
      <value value="2200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sight">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="familiarity">
      <value value="0.3"/>
      <value value="0.5"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="_start-queue-radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wider-exits">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wider-stairs">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="one-way-traffic">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evacuee-staff">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacles">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-signs">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phased-evacuation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="WiderExit" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="population">
      <value value="250"/>
      <value value="500"/>
      <value value="750"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="compliance">
      <value value="0.6"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sight">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="familiarity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="_start-queue-radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wider-exits">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wider-stairs">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="one-way-traffic">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evacuee-staff">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacles">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-signs">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phased-evacuation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smart-signs">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="WiderStairs" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="population">
      <value value="250"/>
      <value value="500"/>
      <value value="750"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="compliance">
      <value value="0.6"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sight">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="familiarity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="_start-queue-radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wider-exits">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wider-stairs">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="one-way-traffic">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evacuee-staff">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacles">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-signs">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phased-evacuation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smart-signs">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="WiderBoth" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="population">
      <value value="250"/>
      <value value="500"/>
      <value value="750"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="compliance">
      <value value="0.6"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sight">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="familiarity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="_start-queue-radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wider-exits">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wider-stairs">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="one-way-traffic">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evacuee-staff">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacles">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-signs">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phased-evacuation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smart-signs">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Obstacles" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="population">
      <value value="250"/>
      <value value="500"/>
      <value value="750"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="compliance">
      <value value="0.6"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sight">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="familiarity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="_start-queue-radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wider-exits">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wider-stairs">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="one-way-traffic">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evacuee-staff">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacles">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-signs">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phased-evacuation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smart-signs">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="OneWay" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="population">
      <value value="250"/>
      <value value="500"/>
      <value value="750"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="compliance">
      <value value="0.6"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sight">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="familiarity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="_start-queue-radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wider-exits">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wider-stairs">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="one-way-traffic">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evacuee-staff">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacles">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-signs">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phased-evacuation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smart-signs">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="DynamicSigns" repetitions="30" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="population">
      <value value="250"/>
      <value value="500"/>
      <value value="750"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="compliance">
      <value value="0.6"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sight">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="familiarity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="_start-queue-radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wider-exits">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wider-stairs">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="one-way-traffic">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evacuee-staff">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacles">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-signs">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phased-evacuation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smart-signs">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Phased" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="population">
      <value value="250"/>
      <value value="500"/>
      <value value="750"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="compliance">
      <value value="0.6"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sight">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="familiarity">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="_start-queue-radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wider-exits">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wider-stairs">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="one-way-traffic">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evacuee-staff">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacles">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-signs">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phased-evacuation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smart-signs">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Staff" repetitions="2000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>evac100</metric>
    <enumeratedValueSet variable="population">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="compliance">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sight">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="familiarity">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="_start-queue-radius">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wider-exits">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wider-stairs">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="one-way-traffic">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evacuee-staff">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacles">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-signs">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="phased-evacuation">
      <value value="false"/>
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
