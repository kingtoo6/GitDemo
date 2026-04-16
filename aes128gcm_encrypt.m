function [ciphertext, auth_tag] = aes128gcm_encrypt(key, iv, plaintext, aad)
% AES-128-GCM加密 + 认证
% 输入:
%   key:       16字节uint8密钥
%   iv:        12字节uint8类型nonce/IV
%   plaintext: 16*n字节uint8类型明文
%   aad:       任意字节uint8附加鉴别数据（可为[]）
% 输出:
%   ciphertext: 密文（与明文等长）
%   auth_tag:   16字节uint8 GCM认证标签

block_size = 16;

% 1. 生成加密核（J0, IV标准拼接）
if numel(iv) ~= 12
    error('IV must be 12 bytes per GCM standard.');
end
J0 = [iv uint8([0 0 0 1])]; % 12字节Nonce + 0x00000001 per RFC

% 2. 计算E(K, J0)：GCM的key block（tag 加密用）
Ek_J0 = aes128_encrypt_block(J0, key);

% 3. 生成计数器序列并进行加密
num_blocks = ceil(numel(plaintext)/block_size);
ciphertext = zeros(size(plaintext),'uint8');
counter = J0;
for i = 1:num_blocks
    counter = gcm_inc32(counter); % J1开始，第一个为J0+1
    keystream = aes128_encrypt_block(counter, key);
    from_idx = (i-1)*block_size+1;
    to_idx = min(i*block_size, numel(plaintext));
    pt_block = uint8(plaintext(from_idx:to_idx));
    ks_block = keystream(1:(to_idx-from_idx+1));
    ciphertext(from_idx:to_idx) = bitxor(pt_block, ks_block);
end

% 4. 计算GHASH认证值
H = aes128_encrypt_block(zeros(1,16,'uint8'), key); % hash子密钥
ghash_in = [gcm_pad(aad), gcm_pad(ciphertext), gcm_lenblock(numel(aad), numel(ciphertext))];
S = gcm_ghash(H, ghash_in);

% 5. 生成tag
auth_tag = bitxor(S, Ek_J0);
disp(['J0_hex: ', sprintf('%02x', J0)]);
disp(['Ek_J0_hex: ', sprintf('%02x', Ek_J0)]);
disp(['H_hex: ', sprintf('%02x', H)]);
disp(['ghash_in_hex: ', sprintf('%02x', ghash_in)]);
disp(['ghash_out_hex: ', sprintf('%02x', S)]);
disp(['Tag_hex: ', sprintf('%02x', auth_tag)]);
end