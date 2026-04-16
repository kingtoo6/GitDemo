function bl = gcm_lenblock(aad_len, ct_len)
% GCM计长度Block，所有长度以bit计数，拼接成16字节
bl = zeros(1,16,'uint8');
aad_bits = uint64(aad_len)*8;
ct_bits  = uint64(ct_len)*8;
bl(1:8) = typecast(swapbytes(aad_bits),'uint8');
bl(9:16) = typecast(swapbytes(ct_bits),'uint8');
end