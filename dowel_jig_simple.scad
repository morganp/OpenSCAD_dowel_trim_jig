// Dowel squaring jig: block with bore, 8 magnet pockets in the top end,
// and a clamp bolt with knurled knob through one side wall.
// Print jig top face up. Pause when pockets are open, insert magnets in the
// pockets you want, resume. Empty pockets are just closed over.
// part = "jig", "bolt" or "assembly" (preview)

include <BOSL2/std.scad>
include <BOSL2/threading.scad>
include <parametric-knob-maker/parametric_knob.scad>

part = "assembly";

dowel_d    = 38.1;
bore_clear = 0.4;
block_w    = 70;
block_h    = 40;

mag_d      = 10;
mag_t      = 3;
mag_clear  = 0.2;
mag_roof   = 0.8;   // solid layer left above magnet

layer_h    = 0.2;
first_h    = 0.2;

// Clamp bolt
bolt_d      = 8;
bolt_pitch  = 1.25;
bolt_len    = 24;      // threaded length
thread_slop = 0.2;     // hole to bolt clearance on thread
bolt_z      = block_h / 2 - 2;
knob_d      = 30;
knob_body_h = 12;      // knob library: main body height
knob_base_h = 3;       // knob library: narrow offset under the body
knob_h      = knob_body_h + knob_base_h;
knurls      = 20;      // grip cutouts
knurl_d     = 4;

bore_d   = dowel_d + bore_clear;
pocket_d = mag_d + mag_clear;
pocket_t = mag_t + mag_clear;
pocket_top = block_h - mag_roof;
pocket_bot = pocket_top - pocket_t;
mid_r    = (bore_d / 2 + block_w / 2) / 2;   // side pocket centre radius
corner_c = 25;                               // corner pocket centre offset, x and y

// Side pockets at 0/90/180/270 deg, corner pockets at 45/135/225/315 deg
pocket_xy = concat(
    [for (a = [0, 90, 180, 270]) [mid_r * cos(a), mid_r * sin(a)]],
    [for (sx = [-1, 1], sy = [-1, 1]) [sx * corner_c, sy * corner_c]]
);

pause_layer = ceil((pocket_top - first_h) / layer_h) + 2;   // first layer above pocket top
echo(str("Pocket floor z=", pocket_bot, " mm, magnet seats at z=", pocket_bot + mag_t));
echo(str("Pause before layer ", pause_layer, " (layer top z=", first_h + (pause_layer - 1) * layer_h, " mm)"));
echo(str("Pocket open until z=", pocket_top, " mm. Insert magnets, then resume."));
echo(str("Pockets: ", len(pocket_xy)));

$fn = 96;

module jig() {
    difference() {
        translate([-block_w / 2, -block_w / 2, 0]) cube([block_w, block_w, block_h]);
        translate([0, 0, -1]) cylinder(d = bore_d, h = block_h + 2);
        translate([0, 0, -0.01]) cylinder(d1 = bore_d + 3, d2 = bore_d, h = 1.5);   // lead-in
        for (p = pocket_xy)
            translate([p[0], p[1], pocket_bot]) cylinder(d = pocket_d, h = pocket_t);
        // Threaded clamp hole through the -X wall, axis along X
        translate([-block_w / 2 - 1, 0, bolt_z])
            rotate([0, 90, 0])
                threaded_rod(d = bolt_d + 2 * thread_slop, l = block_w / 2 - bore_d / 2 + 2,
                             pitch = bolt_pitch, internal = true, bevel = true,
                             anchor = BOTTOM, $fn = 48);
    }
}

// Bolt built along +Z, knob at the bottom (knob on the print bed)
module bolt() {
    // knurled knob from the parametric-knob-maker library, base at z=0
    knob(knob_height = knob_body_h, knob_diam = knob_d, offset_height = knob_base_h,
         num_grip_cutouts = knurls, grip_cutout_diam = knurl_d, knob_color = "orange");
    translate([0, 0, knob_h - 0.01])
        threaded_rod(d = bolt_d, l = bolt_len, pitch = bolt_pitch, bevel2 = true,
                     anchor = BOTTOM, $fn = 48);
}

// Bolt placed in its hole. Tip reaches ~4 mm into the bore.
module bolt_in_place() {
    tip_x = -bore_d / 2 + 4;
    translate([tip_x - (bolt_len + knob_h), 0, bolt_z])
        rotate([0, 90, 0]) bolt();
}

if (part == "jig") jig();
else if (part == "bolt") bolt();
else {
    jig();
    color("orange") bolt_in_place();
}
