function ctr = gcm_inc32(ctr)
% 末四bytes按big-endian加1
val = typecast(uint8(ctr(13:16)), 'uint32');
val = swapbytes(val); % 转为BE
val = mod(double(val)+1, 2^32);
ctr(13:16) = typecast(swapbytes(uint32(val)), 'uint8');
end