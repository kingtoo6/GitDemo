clc; clear; close all;
import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;
import javax.crypto.spec.GCMParameterSpec;

% --------- 参数配置 ----------
key = uint8('thisisakey123456');                % 16字节密钥
iv = uint8('1234567890ab');                     % 12字节IV/Nonce
plaintext = uint8('Hello, MATLAB AES-GCM Example!');
aad = uint8('myAAD');                           % 可选认证数据
disp(['密钥 hex: ', sprintf('%02x', key)]);
disp(['iv hex: ', sprintf('%02x', iv)]);
disp(['明文 hex: ',sprintf('%02x', plaintext)]);

% --------- Java AES-GCM加密 ----------
cipher = Cipher.getInstance('AES/GCM/NoPadding');
keySpec = SecretKeySpec(key, 'AES');
gcmSpec = GCMParameterSpec(128, iv);

cipher.init(Cipher.ENCRYPT_MODE, keySpec, gcmSpec);
cipher.updateAAD(aad);
ciphertextWithTag = cipher.doFinal(plaintext);

tagLength = 16; % 128位tag=16字节

% --- Java字节转Matlab字节流程（关键步骤）---
tmp = typecast(ciphertextWithTag, 'int8');
all_bytes = uint8(mod(double(tmp),256));   % 得到真正0~255字节流

ciphertext = all_bytes(1:end-tagLength);
tag = all_bytes(end-tagLength+1:end);
ciphertext = ciphertext(:).';  % 变为行向量
tag = tag(:).';

disp(['密文 hex: ',sprintf('%02x', ciphertext) ]);
disp(['认证Tag hex: ', sprintf('%02x', tag)]);

% --------- Java AES-GCM解密 ----------
cipher2 = Cipher.getInstance('AES/GCM/NoPadding');
cipher2.init(Cipher.DECRYPT_MODE, keySpec, gcmSpec);
cipher2.updateAAD(aad);

% 合并密文和tag并格式转Java字节 (-128~127)
ciphertextWithTag2 = [ciphertext, tag];
ciphertextWithTag2_java = int8(double(ciphertextWithTag2) - (double(ciphertextWithTag2) > 127)*256);

try
    plainRecovered = cipher2.doFinal(ciphertextWithTag2_java);
    disp(['解密成功: ', char(uint8(plainRecovered(:).'))]);
catch ME
    plainRecovered = [];
    disp(['解密失败，认证失败或数据被篡改.' char(10) ME.message]);
end