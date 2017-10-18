close all;
clear all;

% Reading the list of sequences in the fodler
fileID = fopen('sequence_list.txt','r','n','ISO-8859-15');
C = textscan(fileID,'%s');
fclose( fileID );

% Number of sequences in the follder
sequence_count = length(C{1});  

imgFolder = '/home/mathew/Documents/DATASET/vot2014/';
isColor = false;


%======================  Looping through te sequences =============
for seq_no =1:1:sequence_count

    sequence_title = C{1}{ seq_no };
    display([ '++++Processing ' sequence_title ,' sequence+++++']);

    %  Starting frame number
    start_frame_no =  18;
    % Get all the file names off the images in the sequence
   [ img_names , frame_count, GT ]  =  read_frame_names( imgFolder , sequence_title );
   
   [ obj_rect_corners , objWidth , objHeight] = initial_obj_info( GT , start_frame_no );
    
   p.sz_T = [ objHeight , objWidth];
  
   init_img = imread( img_names( start_frame_no).name);  
    
    if( ~isColor )
       init_img = rgb2gray( init_img );
    end
    init_img = im2double( init_img );
   
   % Templates of the image from the first frame 
  [ template , template_mean, template_std, template_norm ]  = compute_templates( obj_rect_corners , init_img ,  p.sz_T ); 
   
  nT =size( template ,2);
   
   % Dictionary
   B = [ template , eye( prod( p.sz_T)) , -1* eye( prod( p.sz_T))];
   
   p.rel_std_afnv = [0.03,0.0005,0.0005,0.03, 1,1 ];%deviation of the sampling of particle filter
   p.n_sample	= 50;		%number of particles
   aff_obj = corners2affine(obj_rect_corners(:,1:3)  ,p.sz_T );
   map_aff = aff_obj.afnv;
   aff_samples = ones(p.n_sample,1)*map_aff;
   rel_std_afnv = p.rel_std_afnv;
   
   % ==Parameters of the optimization problem
   lambda = 01;
   n = size( B,2);
   
   track_res	= zeros( 6 ,  frame_count );
   track_res(:,start_frame_no) = map_aff;
   
   % update parameter
   sim_th = 0.95;
   aff_samples_array=[];
   aff_samples_array{start_frame_no} = [];

  %======== Looping through the frames in thae sequence ===========
    for frame_no = start_frame_no+1  :1: 60
        curr_img_color = imread( img_names(frame_no ).name);
        if( ~isColor )
            curr_img = rgb2gray( curr_img_color );
        end
        curr_img = im2double( curr_img );
        
        %===========Particle filter============================
            
         %-Draw transformation samples from a Gaussian distribution
        sc			= sqrt(sum(map_aff(1:4).^2)/2);
        std_aff		= rel_std_afnv.*[1, sc, sc, 1, sc, sc ];
        %std_aff		= rel_std_afnv.*[1, sc, sc, 1, sc, sc];
        map_aff		= map_aff + 1e-14;
        aff_samples = draw_sample( aff_samples, std_aff, map_aff);
        
        aff_samples_array{ frame_no } = aff_samples;
        
        [Y, Y_inrange] = crop_candidates( curr_img , aff_samples(:,1:6), p.sz_T);
        if(sum(Y_inrange==0) == p.n_sample)
            sprintf('Target is out of the frame!\n');
        end
        %====Likelihood computation==========
        recon_error = zeros( 1, p.n_sample);
        
        sparse_coefficients = zeros( size( B,2 ) , p.n_sample );
        
        for p_no = 1:p.n_sample
            % Skip the invalid particles
            if Y_inrange( p_no )==0 || sum(abs(Y(:,p_no )))==0
                continue;
            end
            
          [ Y(:, p_no) ,  y_mean , y_std] = whitening( Y(:, p_no) ); %crop is a vector
          y_norm = norm( Y(:, p_no));
          Y(:, p_no) = Y(:, p_no)/ y_norm; % l2-norm
                        
            cvx_begin quiet
                variable  x(n)
                minimize( norm( B*x- Y(:, p_no),2) + lambda  * norm( x,1))
            subject to 
                0 <= x
            cvx_end
            recon_error( p_no ) = norm( Y(:, p_no) - B(:,1:nT) * x(1:nT));
            sparse_coefficients( : , p_no ) = x;
        end
        [best_err ,best_particle_indx]  = min( recon_error );
        best_particle = aff_samples( best_particle_indx, :);
        
        map_aff = best_particle;
        prob = recon_error ./ sum( recon_error);
        [aff_samples, ~] = resample(aff_samples,prob ,map_aff); 
        
        [ B(:,1:nT)  ] = template_update( B(:,1:nT)  , Y(:, best_particle_indx ), sparse_coefficients( : , best_particle_indx )  , sim_th );
       
        % store the output from each frame
        track_res(:, frame_no) = map_aff';
        
        % draw_particle_rectangles( aff_samples , p.sz_T , curr_img_color );
            
            

    end
    
    %================ Display and  Store the results ==============================
    for frame_no = start_frame_no +1 :1: frame_count

        display(['Reading image :' , img_names( frame_no).name ]);

        %=== Reading the first iamge i athae sequence
        curr_img_color = imread( img_names( frame_no).name );


        rect= round(aff2image(track_res(:, frame_no),p.sz_T));
        inp	= reshape(rect,2,4);

        topleft_r = inp(1,1);
        topleft_c = inp(2,1);
        botleft_r = inp(1,2);
        botleft_c = inp(2,2);
        topright_r = inp(1,3);
        topright_c = inp(2,3);
        botright_r = inp(1,4);
        botright_c = inp(2,4);

        out_rect(:,frame_no ) =[ topleft_c; topleft_r; botleft_c;botleft_r;botright_c;botright_r;topright_c; topright_r];




        %cla reset;

        % draw tracking results
        curr_img_color	= double( curr_img_color );
        imshow(uint8( curr_img_color ));
        text(5,10,num2str( frame_no ),'FontSize',18,'Color','r');
        color = [1 0 0];
        drawAffine( track_res(:, frame_no)', p.sz_T, color, 2);
        drawnow;

        %savefig(['/home/mathew/GitWorkspace/matlab/LCKSVD-Tracker/results/', sequence_title , '/', int2str(frame_no),'.fig']);
        saveas(gcf,[ './results/', sequence_title,'/', int2str(frame_no),'.png'])
    end
    
    save(['./results/', sequence_title,'/' , sequence_title,'_output_rect.mat'] ,'out_rect');


        

end
        
        
    
   
  
   
  
    
   
   
   
   
   
   
   
   
   
   
   
   
   
    

        