// Enclosure for Raspberry Pi Zero W + Waveshare 2-CH CAN HAT.
//
// Dimensions: Raspberry Pi Zero W mechanical drawing, Waveshare j25-2_asm.stp.
// Origin: centre of the HAT outline in XY, underside of the floor at z=0.
// +y is the GPIO edge, -y is the CAN terminal edge.
//
// The HAT is 26 mm deeper than the Zero, so the Zero's ports sit under the HAT
// overhang. Cables run straight through that bay and out of the -y wall.
//
// Boards are held by M2.5 self-tapping screws driven down into pilot holes: the
// Zero at all four holes, then the HAT at its two far corners. The HAT's GPIO
// end sits on the header, and the lid presses it down.
//
// part: "base", "lid", "zero", "hat", "plugs", "zero_screws", "hat_screws",
//       "assembly"
part = "assembly";
// layer: export only this colour, because STL can't carry more than one
layer = "";
$fn = 40;

// Measure this on your stack before printing: Zero PCB top to HAT PCB underside.
stack_gap = 14;

clr = 0.5;      // PCB to wall
wall = 2.2;
floor_t = 2;
top_t = 2;
post_h = 3;     // floor to Zero underside; clears header solder tails
pilot_d = 2.2;  // M2.5 self-tapping
zero_pilot_h = 4;
hat_pilot_h = 9;
zero_screw_l = 5;
hat_screw_l = 8;
screw_d = 2.5;
head_d = 5;
head_h = 2;
hold_d = 5.5;   // lid hold-down tube
corner_r = 4;

hat_x = 65.2;  hat_y = 56.4;  hat_t = 1.6;
zero_x = 65;   zero_y = 30;   zero_t = 1.4;
hat_tallest = 10.2;  // DC-DC module above HAT top surface

// Fixing holes, HAT coordinates
hole_x = 29;
gpio_y = 24.3;          // shared by Zero and HAT
zero_far_y = gpio_y - 23;
hat_far_y = -24.7;

zero_edge_y = gpio_y + 3.5 - zero_y;   // Zero's port edge

// Port centres along the Zero's port edge, from the Zero's SD end
hdmi_x = 12.4 - zero_x/2;
usb_x = 41.4 - zero_x/2;
pwr_x = 54 - zero_x/2;
sd_y = zero_edge_y + 16.9;
cam_y = gpio_y + 3.5 - 15;

// CAN terminal blocks, from the STEP file
term0 = [-13.42, -3.02];
term1 = [5.78, 16.18];

// Stack heights
zero_z = floor_t + post_h;
zero_top = zero_z + zero_t;
hat_z = zero_top + stack_gap;
hat_top = hat_z + hat_t;
inner_top = hat_top + hat_tallest + 1;
total_h = inner_top + top_t;

split_z = hat_top;
tongue_h = 3;
fit = 0.15;

in_x = hat_x/2 + clr;
in_y = hat_y/2 + clr;
out_x = in_x + wall;
out_y = in_y + wall;
tongue_x = in_x + wall/2;
tongue_y = in_y + wall/2;

module paint(c) {
    if (layer == "" || layer == c) color(c) children();
}

module rounded(hx, hy, h, r) {
    linear_extrude(h)
        offset(r) square([2*(hx - r), 2*(hy - r)], center = true);
}

module at_holes(xs, ys) {
    for (x = xs, y = ys) translate([x, y, 0]) children();
}

module terminal_cuts(z0, h) {
    for (t = [term0, term1])
        translate([t[0] - 0.6, -out_y - 1, z0])
            cube([t[1] - t[0] + 1.2, out_y + 1 - 21.6, h]);
}

module far_post(sign) {
    x0 = sign > 0 ? 27.2 : -in_x - 0.1;
    translate([x0, -in_y - 0.1, 0])
        cube([in_x + 0.1 - 27.2, in_y + 0.1 + hat_far_y + 2.75, hat_z]);
}

module snap_ridge(sign, grow = 0) {
    for (y = [-12, 12])
        translate([sign*(tongue_x), y, split_z + tongue_h/2])
            rotate([90, 0, 0])
                cylinder(r = 0.5 + grow, h = 14 + 2*grow, center = true, $fn = 16);
}

module base() {
    difference() {
        union() {
            difference() {
                rounded(out_x, out_y, split_z, corner_r);
                translate([0, 0, floor_t])
                    rounded(in_x, in_y, split_z, corner_r - wall);
            }
            // Lid locating tongue
            translate([0, 0, split_z - 0.01]) difference() {
                rounded(tongue_x, tongue_y, tongue_h, corner_r - wall/2);
                translate([0, 0, -1])
                    rounded(in_x, in_y, tongue_h + 2, corner_r - wall);
            }
            for (s = [-1, 1]) snap_ridge(s);

            at_holes([-hole_x, hole_x], [gpio_y, zero_far_y])
                cylinder(d = 6, h = zero_z);
            for (s = [-1, 1]) far_post(s);

            // Mounting ears
            for (s = [-1, 1]) linear_extrude(3) hull() {
                translate([s*(out_x + 5), 0]) circle(d = 10);
                translate([s*(out_x - 2), 0]) square([4, 16], center = true);
            }
        }

        // Screw pilots, blind so the underside stays flat
        at_holes([-hole_x, hole_x], [gpio_y, zero_far_y])
            translate([0, 0, zero_z - zero_pilot_h]) cylinder(d = pilot_d, h = zero_pilot_h + 1);
        at_holes([-hole_x, hole_x], [hat_far_y])
            translate([0, 0, hat_z - hat_pilot_h]) cylinder(d = pilot_d, h = hat_pilot_h + 1);

        // Cable openings under the HAT
        bay_z = floor_t + 1;
        bay_h = hat_z - 1.5 - bay_z;
        for (r = [[-27.2, -13], [2.5, 27.2]])
            translate([r[0], -out_y - 1, bay_z])
                cube([r[1] - r[0], wall + 2, bay_h]);

        // SD card slot, with a finger scoop in the outside face
        translate([-out_x - 1, sd_y - 7, zero_top - 0.5])
            cube([wall + 2, 14, 3.5]);
        translate([-out_x, sd_y, zero_top + 1.2])
            scale([1, 1.6, 1.2]) sphere(r = 4);

        // Camera ribbon slot
        translate([in_x - 1, cam_y - 9, zero_top - 0.5])
            cube([wall + 2, 18, 2.5]);

        terminal_cuts(split_z, tongue_h + 1);

        at_holes([-(out_x + 5), out_x + 5], [0])
            translate([0, 0, -1]) cylinder(d = 4.5, h = 5);
    }
}

// Press the HAT's unscrewed GPIO end onto the header
module hold_downs() {
    at_holes([-hole_x, hole_x], [gpio_y])
        translate([0, 0, hat_top + 0.1])
            cylinder(d = hold_d, h = inner_top - hat_top);
}

module lid() {
    hold_downs();
    difference() {
        translate([0, 0, split_z + fit]) rounded(out_x, out_y, total_h - split_z - fit, corner_r);
        translate([0, 0, split_z])
            rounded(tongue_x + fit, tongue_y + fit, tongue_h + 0.3, corner_r - wall/2);
        translate([0, 0, split_z + tongue_h + 0.2])
            rounded(in_x, in_y, inner_top - split_z - tongue_h - 0.2, corner_r - wall);
        for (s = [-1, 1]) snap_ridge(s, 0.15);

        // Wire entry and screwdriver access, open at the bottom so the lid
        // drops over the terminal blocks
        terminal_cuts(split_z - 1, total_h);

        // Vents
        for (x = [-14:5:21])
            translate([x - 1, 2, inner_top - 1])
                cube([2, 20, top_t + 2]);

        // Power LED window
        translate([-28, 9.5, inner_top - 1]) cylinder(d = 3, h = top_t + 2);
    }
}

module screw(z, l) {
    translate([0, 0, z]) {
        translate([0, 0, -l]) cylinder(d = screw_d, h = l + 0.01);
        cylinder(d = head_d, h = head_h);
    }
}

module zero_screws() {
    paint("#c8c8c8") at_holes([-hole_x, hole_x], [gpio_y, zero_far_y])
        screw(zero_top, zero_screw_l);
}

module hat_screws() {
    paint("#c8c8c8") at_holes([-hole_x, hole_x], [hat_far_y])
        screw(hat_top, hat_screw_l);
}

module zero() {
    paint("#1f7a4d") difference() {
        translate([0, zero_edge_y + zero_y/2, zero_z])
            linear_extrude(zero_t) offset(3)
                square([zero_x - 6, zero_y - 6], center = true);
        at_holes([-hole_x, hole_x], [gpio_y, zero_far_y])
            translate([0, 0, zero_z - 1]) cylinder(d = 2.75, h = 4);
    }
    // 2x20 male header
    paint("#222") translate([-25.4, gpio_y - 2.54, zero_top]) cube([50.8, 5.08, 2.5]);
    // Ports
    paint("#c8c8c8") {
        translate([hdmi_x - 5.6, zero_edge_y - 1, zero_top]) cube([11.2, 7.5, 3.2]);
        for (x = [usb_x, pwr_x])
            translate([x - 4, zero_edge_y - 1.3, zero_top]) cube([8, 5.6, 2.8]);
        translate([-zero_x/2 - 0.8, sd_y - 6, zero_top]) cube([12, 12, 1.4]);
    }
    paint("#111") translate([-18.5, zero_edge_y + 12, zero_top]) cube([12, 12, 1]);
    paint("#444") translate([-3, zero_edge_y + 9, zero_top]) cube([12, 12, 1.1]);
    paint("#e8e0c8") translate([zero_x/2 - 4.2, cam_y - 8.5, zero_top]) cube([4, 17, 1.2]);
}

module hat() {
    paint("#1b4fa0") difference() {
        translate([0, 0, hat_z]) linear_extrude(hat_t) difference() {
            offset(3.3) square([hat_x - 6.6, hat_y - 6.6], center = true);
            // Edge notch
            translate([-hat_x/2 - 1, -8.7]) square([6.1, 17]);
            // Isolation slot
            translate([-20.35, -3.9]) square([45.9, 2.1]);
        }
        at_holes([-hole_x, hole_x], [gpio_y, hat_far_y])
            translate([0, 0, hat_z - 1]) cylinder(d = 3, h = 4);
    }
    // GPIO socket, down to the Zero's header
    paint("#222") translate([-25.5, gpio_y - 2.5, zero_top + 2.5]) cube([51, 5, stack_gap - 2.5]);
    translate([0, 0, hat_top]) {
        paint("#2fa24a") for (t = [[term0, -28], [term1, -27.5]])
            translate([t[0][0], t[1], 0]) cube([10.4, 6.7, 8.8]);
        paint("#111") translate([-25.7, -15.2, 0]) cube([6, 19.6, hat_tallest]);
        paint("#222") {
            translate([-3.63, -6.5, 0]) cube([10.16, 7.3, 2.5]);
            translate([-14.1, 7.16, 0]) cube([11.63, 7.3, 2.5]);
            translate([6.53, 7.16, 0]) cube([11.5, 7.3, 2.5]);
            translate([-12, -19.7, 0]) cube([7.3, 2.5, 2.6]);
            translate([7.3, -19.7, 0]) cube([7.3, 2.5, 2.6]);
        }
        paint("#e6c200") {
            translate([-32.3, -21.1, 0]) cube([2.5, 7.3, 8.7]);
            translate([-32, 13.8, 0]) cube([2.5, 7.3, 8.7]);
            translate([30, -21.1, 0]) cube([2.5, 7.3, 8.7]);
            translate([29.8, -1.6, 0]) cube([2.5, 22.8, 2.6]);
        }
    }
}

// Representative cable ends, for checking they fit through the bay
module plug(x, shell, body) {
    z = zero_top + shell[1]/2 + 0.1;
    paint("#999") translate([x - shell[0]/2, zero_edge_y - 6, z - shell[1]/2])
        cube([shell[0], 6, shell[1]]);
    paint("#1a1a1a") {
        translate([x - body[0]/2, zero_edge_y - 6 - 20, z - body[1]/2])
            cube([body[0], 20, body[1]]);
        translate([x, zero_edge_y - 26, z]) rotate([90, 0, 0])
            cylinder(d = 3.5, h = 30, $fn = 16);
    }
}

module plugs() {
    plug(hdmi_x, [11.2, 3.2], [13, 8]);
    plug(usb_x, [7.5, 2.5], [11, 7]);
    plug(pwr_x, [7.5, 2.5], [11, 7]);
}

if (part == "base") paint("#e8e8ea") base();
else if (part == "lid") paint("#e8e8ea") lid();
else if (part == "zero") zero();
else if (part == "hat") hat();
else if (part == "plugs") plugs();
else if (part == "zero_screws") zero_screws();
else if (part == "hat_screws") hat_screws();
else if (part == "assembly") {
    paint("#e8e8ea") base();
    zero();
    hat();
    plugs();
    zero_screws();
    hat_screws();
    color("#e8e8ea", 0.35) translate([0, 0, 30]) lid();
}
