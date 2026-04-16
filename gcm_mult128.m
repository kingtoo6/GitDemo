function out = gcm_mult128(X, Y)
% GF(2^128) multiplication for AES-GCM (NIST SP 800-38D, Section 6.3).
%
% Implements the standard right-shift binary multiplication algorithm in
% GF(2^128) using the GCM irreducible polynomial:
%   p(x) = x^128 + x^7 + x^2 + x + 1
%
% Bit ordering follows NIST SP 800-38D: the most significant bit (bit 0 of
% the 128-bit string) resides in bit 7 (MSB) of byte 1 of the big-endian
% representation.  The reduction constant is
%   R = 0xe1 00 00 ... 00   (16 bytes)
% because x^128 mod p(x) = x^7 + x^2 + x + 1 = 0xe1 in the GCM bit ordering.
%
% Compatible with NIST SP 800-38D Appendix B GF(2^128) test vectors,
% OpenSSL GCM, and PyCryptodome AES-GCM.
%
% Inputs:
%   X   - 1x16 uint8 row vector (big-endian, byte 1 = most significant byte)
%   Y   - 1x16 uint8 row vector (big-endian, byte 1 = most significant byte)
%
% Output:
%   out - 1x16 uint8 row vector, the product X*Y in GF(2^128)

    % Enforce strict uint8 input; no implicit type conversion allowed.
    X = uint8(X);
    Y = uint8(Y);

    out = zeros(1, 16, 'uint8');   % Z = 0  (accumulator)
    V   = Y;                       % V = Y  (current multiplicand copy)

    % Iterate over all 128 bits of X from MSB (i=0) to LSB (i=127).
    % At step i, bit i of X determines whether to accumulate V into out,
    % then V is right-shifted by 1 (equivalent to multiplying by x in
    % the GCM field element representation).
    for i = 0:127
        % --- Locate bit i of X in the big-endian byte array ---
        byte_idx = floor(i / 8) + 1;   % 1-based byte index (1 = MSB byte)
        bit_pos  = 7 - mod(i, 8);      % bit position within byte (7=MSB, 0=LSB)

        % If X_i = 1, XOR the current V into the accumulator.
        if bitget(X(byte_idx), bit_pos + 1)
            out = bitxor(out, V);
        end

        % --- Prepare V for the next iteration ---
        % Save LSB of V (bit 127, i.e. bit 0 of byte 16) before shifting.
        % This bit determines whether polynomial reduction is needed.
        lsb_V = bitget(V(16), 1);

        % Right-shift the 128-bit V by one bit position.
        % In big-endian: LSB of byte k becomes MSB of byte k+1.
        V = right_shift_128(V);

        % Polynomial reduction: if the shifted-out LSB was 1, apply
        %   V = V XOR R,  where R = 0xe1 || 0x00...0x00
        % (XOR only touches the most significant byte, byte 1.)
        if lsb_V
            V(1) = bitxor(V(1), uint8(0xe1));
        end
    end
end

% -------------------------------------------------------------------------
function y = right_shift_128(x)
% Right-shift a 128-bit big-endian uint8 row vector by exactly 1 bit.
%
% Big-endian convention: byte 1 holds the most significant bits; byte 16
% holds the least significant bits.  For a right shift:
%   - Each byte is shifted right by 1.
%   - The outgoing LSB of byte k becomes the incoming MSB of byte k+1.
%   - The MSB of byte 1 is filled with 0 (no external carry in).
%
% All intermediate values and the output are strictly uint8.

    y     = zeros(1, 16, 'uint8');
    carry = uint8(0);                      % carry from the previous (higher) byte

    for i = 1:16
        % The LSB of the current byte will become the MSB of the next byte.
        new_carry = bitand(x(i), uint8(1));

        % Shift current byte right by 1 and insert the incoming carry as MSB.
        y(i) = bitor(bitshift(x(i), -1), bitshift(carry, 7));

        carry = new_carry;
    end
end