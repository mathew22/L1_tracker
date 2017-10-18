function [ template , template_mean, template_std, template_norm ] = compute_templates( obj_rect_corners , img , template_size )

   template_pos_matrix_x = repmat( [-1 , -0 ,1 ] , 3,1);
   template_pos_matrix_y = repmat( [-1 ; -0 ;1 ] , 1,3);
   template_pos_vec_x = template_pos_matrix_x(:);
   template_pos_vec_y = template_pos_matrix_y(:);
   
   nT = length( template_pos_vec_x); % number of templates
   
   three_corners = obj_rect_corners(:,1:3);
   aff_samples = zeros(  nT , 6);
   
   template = zeros( prod( template_size) , length( template_pos_vec_x) );
   template_mean = zeros( 1, nT );
   template_std = zeros( 1, nT);
   template_norm = zeros( 1, nT);
   
   for i =1:1:length( template_pos_vec_x )
       template_corners = three_corners + [ repmat( template_pos_vec_x( i) , 1, 3 ); repmat( template_pos_vec_y(i) , 1, 3 ) ];
        aff_obj = corners2affine( template_corners  , template_size );
        aff_samples(i,:) = aff_obj.afnv;
        [template(:,i) , Y_inrange] = crop_candidates( img , aff_samples( i,1:6), template_size ); 
        [template(:,i) ,  template_mean(i) , template_std(i)] = whitening( template(:,i) ); %crop is a vector
        template_norm(i) = norm( template(:,i));
        template(:,1) = template(:,i)/ template_norm(i); % l2-norm
        
   end
   
   
 


end