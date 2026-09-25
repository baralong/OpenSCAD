// =====================================================================
// OPENSCAD PALETTE FRAME SET (Adjusted Hinge Offset - No Collisions)
// Base Height = 10.5 mm | Lid Height = 1.5 mm | Total = 12.0 mm
// =====================================================================

$fn = 64;

// --- GLOBAL PARAMETERS ---
wall_thick   = 2.0;    // Solid perimeter wall thickness

// Print Bed Layout Spacing
print_gap    = 10.0;   // Distance between matching Base and Lid
pair_gap     = 130.0;  // Distance between distinct unit pairs

// Plate Mounting Recess (0.5mm deep x 1.0mm wide step)
recess_depth = 0.5;    
recess_width = 1.0;    
c_joiner     = 2.0;    // Internal divider width between ceramic plates

// Frame Heights
base_h       = 10.5;   // Base frame height
lid_h        = 1.5;    // Lid frame height

// Hinge Arch Geometry (Shifted Outward)
hinge_r      = 2.0;    // Outer radius of the arch
hinge_offset = 4;    // Distance from wall face to pivot center (clears wall intersection)
pivot_z      = 6.0;    // Center of pivot axis (midpoint of 12mm total)

// =====================================================================
// CORE FRAME MODULE
// =====================================================================

module palette_pair(c_count, c_size) {
    frame_w     = c_size + (2 * wall_thick);
    frame_l     = (c_count * c_size) + (2 * wall_thick);

    // -----------------------------------------------------------------
    // BASE FRAME (10.5 mm)
    // -----------------------------------------------------------------
    union() {
        difference() {
            // Main Outer Frame
            cube([frame_w, frame_l, base_h]);


            // 0.5mm x 1.0mm Steel Plate Recess
            translate([wall_thick - recess_width, wall_thick - recess_width, -0.1])
                cube([frame_w - 2*(wall_thick - recess_width), frame_l - 2*(wall_thick - recess_width), recess_depth + 0.1]);

             // Central Cavity
            translate([wall_thick, wall_thick, recess_depth])
                cube([frame_w - (2 * wall_thick), frame_l - (2 * wall_thick), base_h]);

            // --- 1.5mm Continuous Outer Edge Fillet ---
            translate([frame_w - 1.5, -0.1, base_h - 1.5]) {
                difference() {
                    // 1.5mm x 1.5mm corner block running the full length (+ 0.2 buffer)
                    cube([1.6, frame_l + 0.2, 1.6]);
                    
                    // Subtract a 1.5mm cylinder to leave the convex rounded edge
                    translate([0, -0.1, 0])
                        rotate([-90, 0, 0])
                            cylinder(r = 1.5, h = frame_l + 0.4);
                }
            }
       }

        // Base Arched Hinge Knuckles (Pushed outward via hinge_offset)
        for (y_pos = [frame_l * 0.1, frame_l * 0.7]) {
            translate([frame_w, y_pos, 0]) {
                difference() {
                    union() {
                        cube([hinge_offset, frame_l * 0.2, pivot_z]);
                        translate([0, 0, pivot_z])
                        cube([hinge_r, frame_l * 0.2, hinge_r]);
                        translate([hinge_offset - hinge_r, 0, pivot_z])
                            rotate([-90, 90, 0])
                                    cylinder(r = hinge_r, h = frame_l * 0.2);
                        
                    }
                    // Inner arch cutout
                    translate([hinge_offset - hinge_r, -0.1, pivot_z])
                        rotate([-90, 0, 0])
                            cylinder(r = hinge_r - 1.0, h = (frame_l * 0.2) + 0.2);
                    
                   
                }
            }
        }
     }

    // -----------------------------------------------------------------
    // LID FRAME (1.5 mm)
    // -----------------------------------------------------------------
     
   translate([pair_gap/2, 0, 0]) {
        union() {
            difference() {
                // Main Solid Lid Frame
                cube([frame_w, frame_l, lid_h]);
                
                // ceramic recess
                translate([wall_thick - recess_width, wall_thick - recess_width, -0.1])
                    cube([frame_w - 2*(wall_thick - recess_width), frame_l - 2*(wall_thick - recess_width), recess_depth + 0.1]);

               opening_size = [c_size - 2*recess_width, c_size - 2*recess_width, lid_h + 0.2];

               // Ceramic Openings 
                for (i = [0 : c_count - 1]) {
                    c_offset_y = wall_thick + (i * (c_size + c_joiner));
                    
                    translate([wall_thick, c_offset_y, -0.1])
                        cube(opening_size);
                }
            }

            // Elevated Lid Hinge Arch (Pushed outward via hinge_offset)
            translate([frame_w, frame_l * 0.3 + 0.2, 0]) {
                difference() {
                    union() {
                        cube([hinge_offset, frame_l * 0.4 - 0.4, pivot_z]);
                            translate([hinge_offset - hinge_r, 0, pivot_z])
                            rotate([-90, 0, 0])
                                cylinder(r = hinge_r, h = frame_l * 0.4 - 0.4);
                    }
                    // Inner arch cutout
                    translate([hinge_offset - hinge_r, -0.1, pivot_z])
                        rotate([-90, 0, 0])
                            cylinder(r = hinge_r - 1.0, h = (frame_l * 0.4) + 0.2);
                }
            }
            translate([frame_w - 1.5, frame_l * 0.3 + 0.2, lid_h]) {
                difference() {
                    union() {
                        cube([1.5, frame_l * 0.4 - 0.4, 1.5]);
                    }
                    // Inner arch cutout
                    translate([0, -0.1, 1.5])
                        rotate([-90, 0, 0])
                            cylinder(r = 1.5, h = (frame_l * 0.4) + 0.2);
                }
            }
        }
    }
}


// =====================================================================
// RENDER ALL PALETTE PAIRS
// =====================================================================

//  2x5
translate([0, 0, 0]) {
    palette_pair(c_count = 2, c_size = 40);
}


// 2x7
//translate([pair_gap, 0, 0]) {
//    palette_pair(steel_w = 42, steel_l = 122, c_count = 3, c_size = 40);
//}
//
//// 2x6
//translate([pair_gap * 2, 0, 0]) {
//    palette_pair(steel_w = 32, steel_l = 122, c_count = 4, c_size = 30);
//}
//
//// 2x4
//translate([pair_gap * 3, 0, 0]) {
//    palette_pair(steel_w = 32, steel_l = 92, c_count = 3, c_size = 30);
//}
//// 2x3
//translate([pair_gap * 4, 0, 0]) {
//    palette_pair(steel_w = 32, steel_l = 62, c_count = 2, c_size = 30);
//}
