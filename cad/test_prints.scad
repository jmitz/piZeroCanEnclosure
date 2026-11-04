// Test prints for the enclosure's pins. Uses the dimensions in enclosure.scad.
//
// test: "pin_fit"     diameter ladder, to try in the real board holes
//       "pin_layout"  all six pins at their true positions and heights, to
//                     seat the assembled Zero and HAT stack on
include <enclosure.scad>

part = "none";
test = "pin_layout";

// pin_fit
fit_sizes = [2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9];
fit_step = 7;           // in x and y; keeps the other pins clear of the board
fit_post_d = 6;
fit_post_h = 3;
fit_pin_h = hat_t + pin_tip;
fit_half_w = 8.5;

module pin_fit() {
    pitch = fit_step*sqrt(2);
    n = len(fit_sizes);
    rotate(-45) {
        translate([-pitch/2, -fit_half_w, 0])
            cube([n*pitch, 2*fit_half_w, floor_t]);
        for (i = [0:n - 1]) translate([i*pitch, 0, 0]) {
            cylinder(d = fit_post_d, h = floor_t + fit_post_h);
            translate([0, 0, floor_t + fit_post_h - 0.01])
                cylinder(d = fit_sizes[i], h = fit_pin_h);
            translate([0, -7.5, floor_t - 0.01]) linear_extrude(0.61)
                text(str(fit_sizes[i]), size = 3.2, halign = "center",
                     font = "Liberation Sans:style=Bold");
            // The enclosure's current size
            if (fit_sizes[i] == pin_d)
                translate([-3, 5.5, floor_t - 0.01]) cube([6, 1.5, 0.61]);
        }
    }
}

// pin_layout
rail_w = 6;

module rail(a, b) {
    linear_extrude(floor_t) hull() {
        translate(a) circle(d = rail_w);
        translate(b) circle(d = rail_w);
    }
}

module pin_post(x, y, z) {
    translate([x, y, 0]) {
        cylinder(d = 6, h = z);
        translate([0, 0, z - 0.01]) cylinder(d = pin_d, h = pin_tip + (z == zero_z ? zero_t : hat_t));
    }
}

module pin_layout() {
    for (s = [-1, 1]) {
        rail([s*hole_x, gpio_y], [s*hole_x, hat_far_y]);
        pin_post(s*hole_x, gpio_y, zero_z);
        pin_post(s*hole_x, zero_far_y, zero_z);
        pin_post(s*hole_x, hat_far_y, hat_z);
    }
    for (y = [gpio_y, zero_far_y, hat_far_y])
        rail([-hole_x, y], [hole_x, y]);
    translate([0, gpio_y - 2, floor_t - 0.01]) linear_extrude(0.61)
        text("GPIO", size = 4, halign = "center",
             font = "Liberation Sans:style=Bold");
}

if (test == "pin_fit") pin_fit();
else if (test == "pin_layout") pin_layout();
