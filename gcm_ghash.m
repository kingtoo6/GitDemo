function Y = gcm_ghash(H, X)
% GCM GHASH gf(2^128)认证积累；X: 数据按16字节block串接；H: 16字节hash子秘钥
n = ceil(numel(X)/16);
Y = zeros(1,16,'uint8');
for i = 1:n
    block = X((i-1)*16+1:min(i*16,numel(X)));
    if numel(block) < 16
        block = [block, zeros(1,16-numel(block),'uint8')];
    end
    Y = gcm_xor128(Y, block);  % Y ^= block
    Y = gcm_mult128(Y, H);     % Y = Y*H (GF(2^128))
end
end