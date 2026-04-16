function [plaintext, computed_tag] = aes128gcm_decrypt(key, iv, ciphertext, aad)
% AES-128-GCM解密+认证校验
% 输入:
%   key, iv, ciphertext, aad: 定义如加密
%   auth_tag: 16字节uint8类型校验标签
% 输出:
%   plaintext: 明文
%   tag_matches: bool，校验是否通过
block_size = 16;
if numel(iv) ~= 12
    error('IV must be 12 bytes per GCM standard.');
end
J0 = [iv uint8([0 0 0 1])];

% 1. 计数器流解密
num_blocks = ceil(numel(ciphertext)/block_size);
plaintext = zeros(size(ciphertext),'uint8');
counter = J0;
for i = 1:num_blocks
    counter = gcm_inc32(counter);
    keystream = aes128_encrypt_block(counter, key);
    from_idx = (i-1)*block_size+1;
    to_idx = min(i*block_size, numel(ciphertext));
    ct_block = uint8(ciphertext(from_idx:to_idx));
    ks_block = keystream(1:(to_idx-from_idx+1));
    plaintext(from_idx:to_idx) = bitxor(ct_block, ks_block);
end

% 2. 计算tag并比对
H = aes128_encrypt_block(zeros(1,16,'uint8'), key);
ghash_in = [gcm_pad(aad), gcm_pad(ciphertext), gcm_lenblock(numel(aad), numel(ciphertext))];
S = gcm_ghash(H, ghash_in);
Ek_J0 = aes128_encrypt_block(J0, key);
computed_tag = bitxor(S, Ek_J0);

end