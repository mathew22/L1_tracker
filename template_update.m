function [ template ] = template_update( template , target_vec, sparse_coefficients , sim_th )

nT = size( template, 2);

a = sparse_coefficients(1:nT);

template_weights = sqrt( diag( template'* template));

% update weights
template_weights = template_weights .* exp( a);

[ max_val, io ] = max( a);
t_io = template(:, io);

%d  = norm( t_io - target_vec );

sim =dot (t_io/norm(t_io), target_vec/norm( target_vec));

if( sim < sim_th )
    [ min_val . io] = min(  template_weights );
    template(:, io ) = target_vec;
    template_weights( io) = median( template_weights );
end
% Normalizeth template weights
template_weights= template_weights./sum( template_weights);
% Preventing skewing
template_weights( template_weights > 0.3) = 0.3; %TODO: How to decide on the value
% norm of the teamplate vectors
template_norm = sqrt( diag( template'* template));
mul_factor =  template_weights./template_norm;
template = template.*repmat( mul_factor' , size( target_vec,1),1);








end