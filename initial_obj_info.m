function  [init_pos , objWidth , objHeight] = initial_obj_info( GT , start_frame_no )

      %Reading the ground truth value of the first frame to initialize
        %the tracker
        xLimit = [ min( GT ( start_frame_no , 1:2:8 )  ) , max( GT( start_frame_no , 1:2:8 )  ) ];
        yLimit = [ min( GT( start_frame_no , 2:2:8 ) ) , max( GT( start_frame_no , 2:2:8 ) ) ];

        % convert to integer since these are pixel co-ordiantes
        xLimit = [ max( floor( xLimit( 1) ) ,1 ) , floor( xLimit( 2 ) ) ];
        yLimit = [ max( floor( yLimit( 1) ) ,1 ) , floor( yLimit( 2 ) ) ];

        %  Finding object width and height
        objWidth = xLimit( 2 ) - xLimit( 1 ) + 1;
        objHeight = yLimit( 2 ) - yLimit( 1 ) + 1;

        % Check to make sure that width and height are odd numbers
        if(mod( objWidth, 2 ) == 0 )
            objWidth = objWidth + 1;
            xLimit( 2 ) = xLimit( 2 ) + 1;
        end
        if( mod( objHeight, 2 ) == 0 )
            objHeight = objHeight + 1;
            yLimit( 2 ) = yLimit( 2 ) + 1;
        end

        display('Object marked in the frame');
        
        % TODO : Send the actural corners instead of the box
        bottom_left = [ yLimit( 2 ), xLimit( 1 ) ];
        top_left = [ yLimit( 1) , xLimit( 1) ];
        top_right = [ yLimit( 1 ), xLimit( 2) ] ;
        bottom_right = [ yLimit( 2 ), xLimit( 2 )];
        
        % position of the object in ht initiala frame
        init_pos = [ top_left' , bottom_left' ,  top_right' , bottom_right' ];

end