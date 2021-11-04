# Notes on Installing Rack-Mounted Servers

These are based on my experience installing rack mounted servers. To
do so at scale necessitates some economies of scale.

1)  Always install racks from bottom to top. This way, you're not
    fighting the elements you've already installed.

1)  Have a variety of plastic bins, tubs, and plastic bags for
    collecting pieces. Cardboard is dusty, and should be kept out of
    data centers. Have at least one cart available to move devices,
    accessories, and parts from the staging area to the data center.

1)  Unpack, identify, and stage *everything* before installing
    *anything*.

1)  Verify all appropriate power, network, FC SAN, etc., connecting
    cables are available in sufficient numbers. One easy way is to
    place all needed accessories with their devices during staging.

1)  Verify your, say, 19" wide by 28" deep racking space is really 19"
    wide and 28" deep. Make sure your front and back frames are close
    enough for your shortest rails to attach.

1)  Install *all* mounting frames and rails before installing *any*
    actual computer hardware.

1)  Use the shortest practical cable length for all power and
    communications cables. Don't use a 5m cable where a 2m cable will
    do. If necessary, stock a large selection. This applies to power
    cords, too. Using a 12 foot power cord for a 4 foot run leaves a
    bunch of power cord that needs to be tied up.

1)  Staging is a good time to determine which devices, computers, cords
    and cables need labeling and to get that labeling done. Devices are
    generally labeled with their name. In large installations, consider
    including the rack and slot identifiers on the label. For cords and
    cables, the labeling scheme is very dependent on what computing
    hardware is getting installed and where the endpoints of a given
    cable are going to attach. I have no objection to mixing labeling
    schemes in a given installation, if necessary. The guiding
    principle should be whether or not a complete stranger could open
    up your racks in two years and figure out how the cables are
    arranged. More intuitive is better.

1)  Install the individual hardware elements one at at time, from
    bottom to top. Don't work against gravity, particularly when having
    to move cables out of your way. Yes, *cable the devices as you go*.
    If you have cable management hardware, use it. Cable management
    hardware gives a much cleaner, more impressive rack. As the devices
    get cabled, and the cables get threaded through the cable
    management arms, temporarily hang the free cable ends over the door
    or along the floor, out of the way.

1)  Disk storage arrays and blade container boxes (IBM Blade Center H,
    etc.) go at the bottom of a rack. If you have both, try to use
    separate racks.


1)  Smaller tape devices go in the middle of the rack, preferably the
    same rack as the storage devices, to minimize the amount of
    squatting or reaching required when changing tapes.

1)  "Pizza boxes," 1U and 2U computers, can go anywhere. Install them
    one at a time, bottom to top. Cable the the device ends as you go.
    You'll connect the free ends and cable tie offs after the hardware
    is installed.

1)  Networking equipment goes on the top of the rack, even if the data
    center connection is coming out of the floor. That DC connection
    will be made early in the installation and is unlikely to change.
    On the other hand, you're going have tens or hundreds of
    connections to make to these devices. You don't want to have to get
    down on your knees for each of them. Networking devices don't
    generally get installed with networking cables. Instead, they'll
    get the free ends of all the other devices when you get to the
    cable tie-off phase.

1)  Connect all power cables to source, and tie them back neatly. This
    can be difficult, because power should be tied next to the walls of
    the rack, with communication cables on top of them.

1)  Connect all fiber channel cables point-to-point, and tie them back
    neatly.

1)  Connect all network cables point-to-point, and tie them back
    neatly. Lay them over the fiber channel cables as needed. (The
    assumption is that network cables will be adjusted more often than
    fiber channel will, and both will need to be adjusted more often
    than power will.)

1)  I don't like single-use zipties/tiewrap. Making a mistake requires
    wasting a ziptie, and possibly leaving litter on the floor. This
    gets irritating in a hurry. Instead, I use velcro-style wraps, or
    waxed string if I'm feeling Old School. Velcro is generally
    easiest to use, but it won't fit through small holes well. In those
    situations, I'll use the waxed string and cut off the ends when I'm
    done tying.

