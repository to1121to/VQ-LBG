clear all;
ncol = 512; nrow = 512; codesize = 512;
file1 = fopen("lenna.raw", 'r');
input1 = fread(file1, [ncol, nrow]);
file2 = fopen("mandrill.raw", 'r');
input2 = fread(file2, [ncol, nrow]);
file3 = fopen("scene.raw", 'r');
input3 = fread(file3, [ncol, nrow]);
file4 = fopen("tiffany.raw", 'r');
input4 = fread(file4, [ncol, nrow]);
init_vec = zeros(4*ncol*nrow/16, 16);
%input vectors
for ntime = 1: 4
    for i = 1: ncol / 4
        for ii = 1: nrow / 4
            for j = 1: 4
                for k = 1: 4
                    switch ntime
                        case 1
                            init_vec((i-1)*nrow/4+ii+(ntime-1)*ncol*nrow/16, (j-1)*4+k) = input1((i-1)*4+j, (ii-1)*4+k);
                        case 2
                            init_vec((i-1)*nrow/4+ii+(ntime-1)*ncol*nrow/16, (j-1)*4+k) = input2((i-1)*4+j, (ii-1)*4+k);
                        case 3
                            init_vec((i-1)*nrow/4+ii+(ntime-1)*ncol*nrow/16, (j-1)*4+k) = input3((i-1)*4+j, (ii-1)*4+k);
                        case 4
                            init_vec((i-1)*nrow/4+ii+(ntime-1)*ncol*nrow/16, (j-1)*4+k) = input4((i-1)*4+j, (ii-1)*4+k);
                    end
                end
            end
        end
    end
end
codebook = zeros(codesize, 16);
check = zeros(4*ncol*nrow/16, 1);
time = 1;
%initial code book by rng
while true
    rng = round(rand * 4*ncol*nrow/16);
    if check(rng, 1) == 0
        codebook(time, :) = init_vec(rng, :);
        check(rng, 1) = 1;
        time = time + 1;
        if time > codesize
            break
        end
    end
end
D_last = 0; 
k = 0;
%save the code that each vector is classified
vector_slot = zeros(1, 4*ncol*nrow/16);
%loop
while true
    %classify
    vector_slot = zeros(1, 4*ncol*nrow/16);
    for i = 1: 4*ncol*nrow/16
        least_dis = inf;
        id = 0;
        for j = 1: codesize
            dis = vec_dis(codebook(j, :), init_vec(i, :));
            if(dis < least_dis)
                least_dis = dis;
                id = j;
            end
        end
        vector_slot(1, i) = id;
    end
    %update center
    newvector = zeros(codesize, 16);
    count = zeros(codesize, 1);
    for i = 1: 4*ncol*nrow/16
        newvector(vector_slot(1, i), :) = newvector(vector_slot(1, i), :) + init_vec(i, :);
        count(vector_slot(1, i), 1) = count(vector_slot(1, i), 1) + 1;
    end
    for i = 1: codesize
        codebook(i, :) = newvector(i, :) ./ count(i, 1);
    end
    %compute the distortion
    k = k + 1;
    D = 0;
    for i = 1: 4*ncol*nrow/16
        D = D + vec_dis(codebook(vector_slot(1, i), :), init_vec(i, :));
    end
    if (D_last - D) / D < 1e-6
        break;
    end
    D_last = D;
end
%output imageVQ
output = zeros(ncol, nrow);

for ntime = 1:4
    t_start = cputime;
    for i = 1: ncol/4
        for ii = 1: nrow/4
            for j = 1: 4
                for k = 1: 4
                    output((i-1)*4+j, (ii-1)*4+k) = codebook(vector_slot(1, (i-1)*nrow/4 + ii + (ntime-1)*ncol*nrow/16), (j-1)*4+k);
                end
            end
        end
    end
    switch ntime
        case 1
            filename = 'lennaVQ.raw';
        case 2
            filename = 'mandrillVQ.raw';
        case 3
            filename = 'sceneVQ.raw';
        case 4
            filename = 'tiffanyVQ.raw';
    end
    fid=fopen(filename,'wb');
    fwrite(fid, output', 'uint8');
    figure;
    imshow(uint8(output'));
    t_end = cputime - t_start
end
%test with other picture
for ntime = 1: 4
    t_start = cputime;
    switch ntime
        case 1
            filename = 'jet.raw';
            size = 512;
        case 2
            filename = 'peppers.raw';
            size = 512;
        case 3
            filename = 'outside1.raw';
            size = 128;
        case 4
            filename = 'outside2.raw';
            size = 128;
    end
    input_vec = zeros(size*size/16, 16);
    file = fopen(filename, 'r');
    input = fread(file, [size, size]);
    for i = 1: size / 4
        for ii = 1: size / 4
            for j = 1: 4
                for k = 1: 4
                    input_vec((i-1)*size/4+ii, (j-1)*4+k) = input((i-1)*4+j, (ii-1)*4+k);
                end
            end
        end
    end
    vector_slot = zeros(1, size*size/16);
    for i = 1: size*size/16
        least_dis = inf;
        id = 0;
        for j = 1: codesize
            dis = vec_dis(codebook(j, :), input_vec(i, :));
            if(dis < least_dis)
                least_dis = dis;
                id = j;
            end
        end
        vector_slot(1, i) = id;
    end
    output = zeros(size, size);
    for i = 1: size/4
        for ii = 1: size/4
            for j = 1: 4
                for k = 1: 4
                    output((i-1)*4+j, (ii-1)*4+k) = codebook(vector_slot(1, (i-1)*size/4 + ii), (j-1)*4+k);
                end
            end
        end
    end
    switch ntime
        case 1
            filename = 'jetVQ.raw';
        case 2
            filename = 'peppersVQ.raw';
        case 3
            filename = 'outside1VQ.raw';
        case 4
            filename = 'outside2VQ.raw';
    end
    fid=fopen(filename,'wb');
    fwrite(fid, output', 'uint8');
    figure;
    imshow(uint8(output'));
    t_end = cputime - t_start
end

function dis = vec_dis(vec_a, vec_b)
    dis = sum((vec_a-vec_b).^2, 'all').^0.5;
end