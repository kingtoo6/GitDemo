clc; clear; close all;


% key = uint8([ 0xab 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00]);
% iv = uint8([ 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00]);


key = uint8(sscanf('feffe9928665731c6d6a8f9467308308', '%2x')).';
iv = uint8(sscanf('cafebabefacedbaddecaf888', '%2x')).';
plaintext = uint8(sscanf('d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39', '%2x')).';
aad = uint8(sscanf('feedfacedeadbeeffeedfacedeadbeefabaddad2', '%2x')).';

% 【准备】
disp('-----准备----- ');
disp(['key_hex: ', sprintf('%02x', key)]);
disp(['iv_hex: ', sprintf('%02x', iv)]);
disp(['plaintext_char:',char(plaintext)]);
disp(['plaintext_hex: ', sprintf('%02x', plaintext)]);
disp(['aad_char:',char(aad)]);
disp(['aad_hex: ', sprintf('%02x', aad)]);

% 【加密】
disp('-----加密认证----- ');
[ciphertext, tag] = aes128gcm_encrypt(key, iv, plaintext, aad);
disp(['ciphertext_hex: ', sprintf('%02x', ciphertext)]);
disp(['tag_hex: ', sprintf('%02x', tag)]);
%tag0 = 58e2fccefa7e3061367f1d57a4e7455a;

% 【传输】
ciphertext1 = ciphertext;
aad1 = aad;
tag1 = tag;
%ciphertext1 = uint8([0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01]);
% aad1 = uint8([0x00 0x01 0x02 0x03 0x04]);

% 【解密】
disp('-----解密认证----- ');
[plain_out, computed_tag] = aes128gcm_decrypt(key, iv, ciphertext1, aad1);

% 【认证】
disp(['computed_tag_hex: ', sprintf('%02x', computed_tag)]);
 if all(computed_tag(:)==tag1(:))
     disp('认证通过');
 else
     disp('认证失败');
 end

 if all(plain_out==plaintext)
     disp('明文一致');
 else
     disp('明文不一致');
 end
disp(['plain_out_hex: ', sprintf('%02x', plain_out)]);
disp(['plain_out_char:',char(plain_out)]);