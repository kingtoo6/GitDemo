
clc; clear; close all;

% H = uint8([0x80,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);  % x^127
% X = uint8([0x01,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]);      % x
% H = uint8(sscanf('66e94bd4ef8a2c3b884cfa59ca342b2e', '%2x')).';
% X = uint8(sscanf('00000000000000000000000000000001', '%2x')).';
X = uint8([0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 ...
           0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x01]);
H = uint8([0x66 0xe9 0x4b 0xd4 0xef 0x8a 0x2c 0x3b ...
           0x88 0x4c 0xfa 0x59 0xca 0x34 0x2b 0x2e]);
%  H = uint8([0x66,0xe9,0x4b,0xd4,0xef,0x8a,0x2c,0x3b,0x88,0x4c,0xfa,0x59,0xca,0x34,0x2b,0x2e]);
%  X = uint8([0x03,0x88,0xda,0xce,0x60,0xb6,0xa3,0x92,0xf3,0x28,0xc2,0xb9,0x71,0xb2,0xfe,0x78]);
result = gcm_mult1281(X, H);
disp(['result_hex: ', sprintf('%02x', result)]);
% disp('expected (decimal):'); disp(uint8([0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]));
% 
% expected = uint8([0x5e,0x2e,0xc7,0x46,0x91,0x70,0x62,0x88,0x2c,0x85,0xb0,0x68,0x50,0x33,0xa2,0x92]);
% result = gcm_mult1281(X, H);
% disp('expect (decimal):'); disp(expected);
% disp('result (decimal):'); disp(result);
% 
% % 
% function z = gcm_mult1281(x, y)
% % Galois域GF(2^128)乘法，完全bit级实现
% r  = uint8([226 0 0 0 0 0 0 0 0 0 0 0 0 0 0 87]); % 0xE1000000000000000000000000000000
% z = zeros(1,16,'uint8');
% v = x;
% for i = 0:127
%     if bitget(y(floor(i/8)+1), 8-mod(i,8))
%         z = bitxor(z, v);
%     end
%     if bitget(v(16),1)
%         v = bitshift([v 0],-1);
%         v = v(1:16);
%         v = bitxor(v, r);
%     else
%         v = bitshift([v 0],-1);
%         v = v(1:16);
%     end
% end
% end
% 
% function Z = gcm_mult1281(X, Y)
% % GF(2^128) 乘法：Z = X * Y mod (x^128 + x^7 + x^2 + x + 1)
% % 输入：X, Y —— 16字节 uint8 行向量（大端表示，即第一个字节为最高位）
% % 输出：Z —— 16字节 uint8 行向量
% 
%     Z = zeros(1, 16, 'uint8');          % 初始化累加器为0
%     V = Y;                              % 将V初始化为Y
% 
%     for k = 0:127                      % 遍历128位，从最高位到最低位
%         % 定位X中第k位所在的字节和位号（k=0对应最高位，即第127位）
%         byte_idx = floor(k / 8) + 1;    % 字节索引（1~16）
%         bit_idx  = 8 - mod(k, 8);       % 位号（8为最高位，1为最低位）
% 
%         % 若X的该位为1，则累加V
%         if bitand(X(byte_idx), bitshift(uint8(1), bit_idx - 1))
%             Z = bitxor(Z, V);
%         end
% 
%         % ---- 将V左移一位，并模不可约多项式 ----
%         % 检查移位前V的最高位（第1字节的第8位）
%         carry = bitand(V(1), uint8(0x80)) ~= 0;
% 
%         % 手动进行128位左移：每个字节左移1位，并从下一个字节借入最高位
%         for j = 1:15
%             V(j) = bitor(bitshift(V(j), 1), bitshift(V(j+1), -7));
%         end
%         V(16) = bitshift(V(16), 1);     % 最后一个字节没有来自更低字节的进位
% 
%         % 若移位前最高位为1，则需模去多项式 x^128 + x^7 + x^2 + x + 1
%         % 等价于对最低字节异或 0xE1
%         if carry
%             V(16) = bitxor(V(16), uint8(0xE1));
%         end
%     end
% end
% 
% 
% function Z = gcm_mult1281(X, Y)
% % GF(2^128) 乘法：Z = X * Y mod (x^128 + x^7 + x^2 + x + 1)
% % 输入 X, Y 为 16 字节 uint8 行向量（大端表示）
% % 本实现从最低位（x^0）开始遍历，正确匹配位权与幂次。
% 
%     Z = zeros(1, 16, 'uint8');
%     V = Y;
% 
%     for i = 0:127
%         % ---- 获取 X 的第 i 位（从最低位开始，i=0 对应最低位）----
%         % 大端字节序下，最低位是最后一个字节的第 1 位（位号 1）
%         byte_idx = 16 - floor(i / 8);    % 字节索引：i=0→16, i=127→1
%         bit_idx  = 8 - mod(i, 8);        % 位号：1~8，8 为最低位
%         if bitand(X(byte_idx), bitshift(uint8(1), 8-bit_idx))
%             Z = bitxor(Z, V);
%         end
% 
%         % ---- 将 V 左移一位（乘以 x），并模约减 ----
%         carry = bitand(V(1), uint8(0x80)) ~= 0;   % 检查最高位
%         % 手动 128 位左移
%         for j = 1:15
%             V(j) = bitor(bitshift(V(j), 1), bitshift(V(j+1), -7));
%         end
%         V(16) = bitshift(V(16), 1);
%         if carry
%             V(16) = bitxor(V(16), uint8(0x87));
%         end
%     end
% end

% function out = gcm_mult1281(X, Y)
%     out = zeros(1, 16, 'uint8');
%     V = Y;
%     for i = 0:127
%         byte = floor(i / 8) + 1;
%         bit = 7 - mod(i,8);
%         if bitget(X(byte), bit+1)
%             out = bitxor(out, V);
%         end
%         lsb = bitget(V(16),1);
%         V = left_shift_128(V);
%         if lsb
%             V = bitxor(V, [227 zeros(1,15,'uint8')]);
%         end
%     end
% end
% 
% function y = left_shift_128(x)
%     y = zeros(1,16,'uint8');
%     carry = 0;
%     for i = 16:-1:1
%         v = double(x(i));
%         y(i) = bitand(bitshift(v,1) + carry, 255);
%         carry = bitshift(v,-7);
%     end
% end