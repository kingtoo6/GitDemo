function out = gcm_xor128(a, b)
% 16字节异或
out = bitxor(uint8(a), uint8(b));
end