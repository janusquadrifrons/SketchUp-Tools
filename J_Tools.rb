# "Copyright 2022, janusquadrifrons"

# API hook
require "sketchup.rb" 

# Show Ruby console at start
SKETCHUP_CONSOLE.show 

# Command Class - ProjectToLine : Project a point to a line
class ProjectToLine

    # Initialize the input point upon start
    def activate
        @input = Sketchup::InputPoint.new
        @isPicked = false
        #@edges = Sketchup::InputPoint.new
    end

    # Left click response in design window
    def onLButtonDown flags, x, y, view
        if @isPicked == false
            @input.pick view, x, y
            Sketchup::set_status_text "Left Click", SB_VCB_LABEL
            pos = @input.position
            str = "%.2f, %.2f, %.2f" % [pos.x, pos.y, pos.z]
            Sketchup::set_status_text str, SB_VCB_VALUE
            @isPicked = true
            puts "Left button down - Point Picked"
        else
            # Retrieve enttity on current cursor location via PickHelper object
            pickhelper = view.pick_helper
            count = pickhelper.do_pick(x, y)
            best_picked = pickhelper.best_picked
            puts pickhelper.count
            puts "Entity Type → " + best_picked.to_s + " ←" # returns → Sketchup::Edge 

            best_picked_line = best_picked.line
            puts "Entity Type → " + best_picked_line.to_s + " ←" # returns → [Point3d(-83.3837, 161.118, 0), Vector3d(0.77154, -0.636181, 0)]

            @entity_path_list = pickhelper.path_at(0)
            pos = @input.position
            puts "@input → " + @input.to_s + " ←" # returns → Sketchup::InputPoint
            puts "Input Position → " + pos.to_s + " ←"
            
            input_pt = [pos.x, pos.y, pos.z]
            input_pt_2 = Geom::Point3d.new(pos.x, pos.y, pos.z) # Alt-2 : aynı sonucu verir

            puts "input_pt Input Position Each → " + input_pt.to_s + " ←"
            puts "input_pt_2 Input Position Each → " + input_pt_2.to_s + " ←"

            projected_point = input_pt.project_to_line(best_picked_line)    # input_pt → wrong arg type dedi
                                                                            # @input → undefined method 
            ents = Sketchup.active_model.entities 
            ents.add_line(input_pt, projected_point)

            puts @isPicked
            puts "Left button down - Edge Selected"
        end
    end
end

########################################################################################

# Command Class - LineFromOrigin : Connect a point to the origin
class LineFromOrigin

    # Initialize the input point upon start
    def activate
        @input_lfo = Sketchup::InputPoint.new
        puts "LİneFromOrigin : Activated."
    end

    # Left click response in design window
    def onLButtonDown flags, x, y, view

        # Retrieve enttity on current cursor location via PickHelper object
        @input_lfo.pick view, x, y
        Sketchup::set_status_text "Line From Origin", SB_VCB_LABEL
        pos = @input_lfo.position
        str = "%.2f, %.2f, %.2f" % [pos.x, pos.y, pos.z]
        Sketchup::set_status_text str, SB_VCB_VALUE
        puts "LineFromOrigin : Left button down - point picked"
        pos = @input_lfo.position

        ents = Sketchup.active_model.entities
        ents.add_line [0,0,0], [pos.x, pos.y, pos.z]

    end
end

########################################################################################

# Command Class - ViewToFace : Align current view to a face
class ViewToFace

    def activate
        puts "ViewToFace : Activated."
    end

    # Left click response in design window
    def onLButtonDown flags, x, y, view
        face = pick_face(view, x, y)
        if face
            align_view_to_face(view, face)
        else
            UI.messagebox("No face was picked.")
        end
    end
    def pick_face(view, x, y)
        ph = view.pick_helper
        ph.do_pick(x, y)
        face = ph.picked_face
        if face && face.is_a?(Sketchup::Face)
            return face
        else
            return nil
        end
    end

    def align_view_to_face(view, face)
        normal = face.normal.to_a # Convert Geom::Vector3d to Array
        view.camera.set(SKETCHUP_CAMERA_PERSPECTIVE, normal)
        view.refresh
    end
end

module AlignViewToFace  
    extend self

    def select_face_and_align_view
        model = Sketchup.active_model
        view = model.active_view
        face = pick_face
        if face && face.is_a?(Sketchup::Face)
            normal = face.normal
            view.camera.set(view.camera.eye, view.camera.target, normal)
            view.refresh
            UI.messagebox("View aligned to face.")
        else
            UI.messagebox("No face was picked.")
        end
    end

    def pick_face
        model = Sketchup.active_model
        view = model.active_view
        ph = view.pick_helper
        ph.do_pick(view.cursor_pick_ray, Sketchup::PickHelper::PICK_ANY)
        face = ph.picked_face
        return face
    end
end

########################################################################################

# Command Class - SeparateBlcoks : Extracts and saves all components and groups to separate files in "Blocks" folder of current file path
class SeparateBlocks

    # Initialize the input point upon start
    def self.separate_blocks
        puts "Starting to separate blocks."

        model = Sketchup.active_model
        if model.nil?
            puts "Error: No active model"
            UI.messagebox("Error: No active model. Please open a SketchUp model first.")    
            return
        end

        definitions = model.definitions
        if definitions.length == 0
            puts "Error: No components or groups found"
            UI.messagebox("Error: No components or groups found in the model.")
            return
        end

        begin
            # Create a new folder to save the blocks
            blocks_folder = File.join(File.dirname(model.path), "Blocks") # --- File.dirname(model.path) : returns the path of the current file
            Dir.mkdir(blocks_folder) unless File.directory?(blocks_folder) # --- Dir.mkdir : creates a new directory
            puts "Blocks folder created or already exist at #{blocks_folder}"
  
            component_count = 0
            group_count = 0

            # Iterate through all definitions
            definitions.each do |definition|
                next if definition.image?
                next if definition.group?
                next if definition.name.empty?
                next if definition.deleted?
  
                begin

                    # Create a new model by saving a blank SketchUp file
                    new_model = Sketchup.file_new
                    new_entities = new_model.active_entities
                    
                    # Add an instance of the component to the new model
                    new_entities.add_instance(definition, Geom::Transformation.new)

                    # Save the new model
                    filename = File.join(blocks_folder, "#{definition.name}.skp")
                    new_model.save(filename)
                    puts "Saved #{definition.name} to #{filename}"

                    # Close the new model
                    new_model.close

                    component_count += 1
                rescue => error
                    puts "Error saving #{definition.name}: #{error.message}"
                end
            end

            if component_count > 0
                message = "#{component_count} components have been saved to the 'Blocks' folder."
                puts message
                UI.messagebox(message)
            else
                puts "No components were saved."
                UI.messagebox("No components were saved.")
            end
        rescue => error
            puts "Error in separete_blcoks method: #{error.message}"
            UI.messagebox("Error: #{error.message}")
        end
    end
end

# Create the command objects
cmd_projet_to_line = UI::Command.new("J_ProjectToLine") {
    Sketchup.active_model.select_tool ProjectToLine.new
}
cmd_line_from_origin = UI::Command.new("J_LineFromOrigin") {
    Sketchup.active_model.select_tool LineFromOrigin.new
}
cmd_view_to_face = UI::Command.new("J_ViewToFace") {
    Sketchup.active_model.select_tool ViewToFace.new
}
cmd_separate_blocks = UI::Command.new("J_SeparateBlocks") {
    puts "SeparateBlocks command activated."
    SeparateBlocks.separate_blocks
}

# Add menu items and relate to commands
j_menu = UI.menu("Extensions")
j_menu.add_separator
j_submenu = j_menu.add_submenu("J_Tools")
j_submenu.add_item cmd_projet_to_line
j_submenu.add_item cmd_line_from_origin
j_submenu.add_item cmd_view_to_face
j_submenu.add_item cmd_separate_blocks
j_submenu.add_item("Select face and align view") do 
    AlignViewToFace.select_face_and_align_view
end

# Add a toolbar
j_toolbar = UI::Toolbar.new "J_Tools"
j_toolbar.show

# Icon definitions
icon_project_to_line = File.join(__dir__, "J_Tools_icons", "projecttoline_24.png")
cmd_projet_to_line.small_icon = icon_project_to_line
cmd_projet_to_line.large_icon = icon_project_to_line
cmd_projet_to_line.tooltip = "J_ProjectToLine"
cmd_projet_to_line.status_bar_text = "Project your point to your lines."

icon_line_from_origin = File.join(__dir__, "J_Tools_icons", "linefromorigin_24.png")
cmd_line_from_origin.small_icon = icon_line_from_origin
cmd_line_from_origin.large_icon = icon_line_from_origin
cmd_line_from_origin.tooltip = "J_LineFromOrigin"
cmd_line_from_origin.status_bar_text = "Connect your point to the origin."

icon_view_to_face = File.join(__dir__, "J_Tools_icons", "viewtoface_24.png")
cmd_view_to_face.small_icon = icon_view_to_face
cmd_view_to_face.large_icon = icon_view_to_face
cmd_view_to_face.tooltip = "J_ViewToFace"
cmd_view_to_face.status_bar_text = "Align your view to selected face."

icon_separate_blocks = File.join(__dir__, "J_Tools_icons", "separateblocks_24.png")
cmd_separate_blocks.small_icon = icon_separate_blocks
cmd_separate_blocks.large_icon = icon_separate_blocks
cmd_separate_blocks.tooltip = "J_SeparateBlocks"
cmd_separate_blocks.status_bar_text = "Extract and save all components and groups to separate files in 'Blocks' folder."

# Insert commands to the toolbar
j_toolbar.add_item cmd_projet_to_line 
j_toolbar.add_item cmd_line_from_origin
j_toolbar.add_item cmd_view_to_face
j_toolbar.add_item cmd_separate_blocks

puts "Menu and toolbaritems added."


