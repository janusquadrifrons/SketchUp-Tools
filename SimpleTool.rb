class SimpleTool

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
    
=begin
# Respond to right-clicks in the design window
def onRButtonDown flags, x, y, view
    @input.pick view, x, y
    Sketchup::set_status_text "Right click ", SB_VCB_LABEL
    pos = @input.position
    str = "%.2f, %.2f, %.2f" % [pos.x, pos.y, pos.z]
    Sketchup::set_status_text str, SB_VCB_VALUE
end
=end  
=begin    
    # Respond to right-clicks in the design window
    def onRButtonDown flags, x, y, view
        ents = Sketchup.active_model.entities
        @input.pick view, x, y
        pos = @input.position
        ents.add_line [pos.x, pos.y, pos.z], [0,0,0]        
    end
=end
=begin
    def onRButtonUp flags, x, y, view
        ents = Sketchup.active_model.entities
        @edges.edge view, x, y
        pt1 = @edges.start
        pos_pt1 = pt1.position
        pt2 = @edges.end
        pos = @input.position
        ents.add_line [pos.x, pos.y, pos.z], [pos_pt1.x, pos_pt1.y, pos_pt1.z] 
    end
=end
=begin
    def onRButtonUp flags, x, y, view
        puts "Right button down"
        # Retrieve enttity on current cursor location via PickHelper object
        pickhelper = view.pick_helper
        count = pickhelper.do_pick(x, y)
        best_picked = pickhelper.best_picked
        puts pickhelper.count

        @entity_path_list = pickhelper.path_at(0)
        pos = @input.position
        input_pt =  [pos.x, pos.y, pos.z]
        projected_point = input_pt.project_to_line(best_picked)
        pp_pos = projected_point.position
        ents = Sketchup.active_model.entities 
       
        ents.add_line [0,0,0], [pp_pos.x, pp_pos.y, pp_pos.z]
    end
=end
end


# Create the command object
simple_cmd = UI::Command.new("SimpleTool") {
    Sketchup.active_model.select_tool SimpleTool.new
}

# Add the Command to the Tools manu
tool_menu = UI.menu "Tools"
tool_menu.add_separator
tool_menu.add_item simple_cmd