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

//Pan Dimensions
pan_w        = 16.0;  // Width of the pan
pan_l        = 19.0;  // Length of the pan
// Frame Heights
base_h       = 10.5;   // Base frame height
lid_h        = 1.5;    // Lid frame height

// Hinge Arch Geometry (Shifted Outward)
hinge_r      = 2.0;    // Outer radius of the arch
hinge_offset = 4;    // Distance from wall face to pivot center (clears wall intersection)
pivot_z      = 6.0;    // Center of pivot axis (midpoint of 12mm total)

// Base Frame Label Engraving
engrave_depth = 0.1;  // Depth cut into the end wall
engrave_size  = 1;    // Font size of the engraved label


// Helper: 1D pan count for length L and pan dimension P (< 0.25*P overhang per side)
function max_pans_1d(L, P) = floor((L + 0.5 * P - 0.001) / P);

// Calculates total outer extent [X, Y] for a given orientation
function calc_extent(c_size, c_count, px, py) = 
    [ max_pans_1d(c_size, px) * px, 
      max_pans_1d(c_size * c_count, py) * py ];
      
// Helper function to calculate total overhang past the tile line
function total_overhang(extent, c_size, c_count) = 
    max(0, extent.x - c_size) + max(0, extent.y - (c_size * c_count));
          
// MAIN FUNCTION: Returns the [X, Y] outer extent that maximizes total pan count
function get_best_pan_extent(c_size, c_count) = 
    let (
        extA = calc_extent(c_size, c_count, pan_w, pan_l),
        extB = calc_extent(c_size, c_count, pan_l, pan_w)
    )
    // 1. Pick the one with the least total overhangS
    (total_overhang(extA, c_size, c_count) < total_overhang(extB, c_size, c_count)) ? extA : extB;

// Given a chosen extent, figure out which orientation fits exactly and return the pan count
function get_pan_count(pan_extent) = 
    (abs(pan_extent.x % pan_w) < 0.001 && abs(pan_extent.y % pan_l) < 0.001) ?
        (pan_extent.x / pan_w) * (pan_extent.y / pan_l) :
        (pan_extent.x / pan_l) * (pan_extent.y / pan_w);
// =====================================================================
// CORE FRAME MODULE
// =====================================================================
module palette_pair(c_count, c_size) {
    pan_w_per_c = pan_w / c_size;
    pan_l_per_c = pan_l / c_size;
    pans_extent_base = get_best_pan_extent(c_size, c_count);
    pan_count = get_pan_count(pans_extent_base);
    pans_extent = pans_extent_base + [0.1, 0.1];
    frame_w     = max(c_size + (2 * recess_width), pans_extent.x + (2 * wall_thick));
    frame_l     = max(c_size * c_count + (2 * recess_width), pans_extent.y + (2 * wall_thick));

    // -----------------------------------------------------------------
    // BASE FRAME (10.5 mm)
    // -----------------------------------------------------------------
    union() {
        difference() {
            // Main Outer Frame
            cube([frame_w, frame_l, base_h]);


            // 0.5mm x 1.0mm Steel Plate Recess
            plate_dim = [frame_w - 2*(wall_thick - recess_width), frame_l - 2*(wall_thick - recess_width), recess_depth + 0.1];
            translate([wall_thick - recess_width, wall_thick - recess_width, -0.1])
                cube(plate_dim);
            echo(str("plate=", plate_dim, " c_size=", c_size, " c_count=", c_count, " total_pans=", pan_count));

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

            // Engraved label (plate size + half-pan count) on the y=0 end wall
            // Lower local $fn: text glyph curves don't need the model's global facet count
            translate([1, -0.05, 1])
                rotate([-90, 0, 0])
                    linear_extrude(height = engrave_depth + 0.05, $fn = 8)
                        mirror([0, 1, 0])
                            text(str(plate_dim[0], "x", plate_dim[1], "mm ", pan_count, " pans"), size = engrave_size, halign = "left", valign = "bottom");
        }

        pan_cube = [pans_extent.x - 0.2, pans_extent.y - 0.2, base_h - 0.1];
        // show where the pans fit
        %translate([(frame_w - pan_cube.x)/2, (frame_l - pan_cube.y)/2, 0])
            cube(pan_cube);

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
                c_safe_size = c_size + 0.1;
                // ceramic recess
                translate([(frame_w - c_safe_size)/2, ((frame_l - (c_safe_size * c_count))/2), -0.1]) {
                    cube([c_safe_size, c_safe_size * c_count, recess_depth + 0.1]);


                    opening_size = [c_size - (2*recess_width), c_size - (2*recess_width), lid_h + 0.2];
                    // Ceramic Openings 2
                    opening_offset = (c_safe_size - opening_size[0])/2;
                    for (i = [0 : c_count - 1]) {
                        c_offset_y = opening_offset + (i * c_safe_size);
                        
                        translate([opening_offset, c_offset_y, 0])
                            cube(opening_size);
                    }
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

// Define all pairs of c_count and c_size for rendering
pairs = [for (c_count = [2: 4], c_size = [30, 40]) [c_count, c_size]];
// render all palette pairs
for (pair_count = [0 : len(pairs) - 2]) { // skip the last one
    translate([pair_gap * pair_count, 0, 0]) {
        palette_pair(c_count = pairs[pair_count][0], c_size = pairs[pair_count][1]);
    }
}

