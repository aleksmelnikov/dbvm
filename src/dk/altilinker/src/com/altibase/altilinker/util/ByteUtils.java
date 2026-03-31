/** 
 *  Copyright (c) 1999~2017, Altibase Corp. and/or its affiliates. All rights reserved.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License, version 3,
 *  as published by the Free Software Foundation.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
 
package com.altibase.altilinker.util;

import java.nio.ByteBuffer;
import java.lang.String;

public final class ByteUtils
{
    private static final char[] HEX_LITERALS_L   = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f' };
    private static final char[] HEX_LITERALS_U   = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F' };

    private ByteUtils()
    {
    }

    /**
     * Checks if a character can be written as a Hex String.
     *
     * @param c The character to check
     * @return true if [0-9a-fA-F], false otherwise
     */
    public static boolean isHexCharacter(char c)
    {
        if (('0' <= c && c <= '9') ||
            ('a' <= c && c <= 'f') ||
            ('A' <= c && c <= 'F'))
        {
            return true;
        }
        return false;
    }

    /**
     * Converts a hex string to a byte array.
     * <p>
     * If the hex string is not even, the lower 4 bits of the last byte are filled with zeros.
     *
     * @param aHexString hex string to convert to a byte array
     * @return The converted byte array. An array that is null if the hex string is null, or has a length of 0 if the string is empty.
     */
    public static byte[] parseByteArray(String aHexString) throws Exception
    {
        return parseByteArray(aHexString, true);
    }

    /**
     * Converts a hex string to a byte array.
     * <p>
     * If the length of the hex string is not a multiple of 2, it may be padded with zeros or an exception may be thrown.
     * If padding is used when it is not a multiple of 2, the lower 4 bits of the last byte are filled with zeros,
     * and if padding is not used, an exception is thrown.
     *
     * @param aHexString The hex string to be converted to a byte array
     * @param aUsePadding Whether to pad with zeros when the hex string is not a multiple of 2.
     * @return The converted byte array. An array that is null if the hex string is null, or has a length of 0 if it is an empty string.
     * @exception IllegalArgumentException If the hex string is invalid
     * @exception IllegalArgumentException If padding is not used and the hex string is not a multiple of 2
     */
    public static byte[] parseByteArray(String aHexString, boolean aUsePadding) throws Exception
    {
        if (aHexString == null)
        {
            return null;
        }

        int sBufSize = aHexString.length() / 2;
        if ((aHexString.length() % 2) == 1)
        {
            if (aUsePadding)
            {
                sBufSize++;
            }
            else
            {
                throw new Exception("Invalid hex string length");
            }
        }
        byte[] sBuf = new byte[sBufSize];
        for (int i = 0; i < aHexString.length(); i++)
        {
            char c = aHexString.charAt(i);
            if (!ByteUtils.isHexCharacter(c))
            {    
                String sExString = new String( "Invalid hex the " + String.valueOf(i) + 
                                               " element: "+ String.valueOf(c) ) ; 
                throw new Exception( sExString );

            }
            c |= 0x20; // to lowercase. Since it has been confirmed to be a hex char, this is acceptable.
            int v = (c < 'a') ? (c - '0') : (10 + c - 'a');
            if ((i % 2) == 0)
            {
                v = v << 4;
            }
            sBuf[i / 2] |= v;
        }
        return sBuf;
    }

    /**
     * Converts a byte array to a hex string.
     *
     * @param aByteArray The byte array to be converted to a hex string
     * @return The converted hex string. "null" if the byte array is null, and an empty string if the length is 0.
     */
    public static String toHexString(byte[] aByteArray) throws Exception
    {
        return toHexString(aByteArray, 0);
    }

    /**
     * Converts a byte array to a hex string.
     *
     * @param aByteArray The byte array to be converted to a hex string
     * @param aStartIdx The first index (inclusive)
     * @param aEndIdx The last index (exclusive)
     * @return The converted hex string. "null" if the byte array is null, and an empty string if the length is 0.
     * @exception IllegalArgumentException If the argument is invalid
     */
    public static String toHexString( byte[] aByteArray, 
                                      int    aStartIdx,
                                      int    aEndIdx ) throws Exception
    {
        return toHexString(aByteArray, aStartIdx, aEndIdx, 0, null, false);
    }

    /**
     * Converts a byte array to a hex string.
     *
     * @param aByteArray The byte array to convert to a hex string
     * @param aSpacingBase The unit for spacing. If 0, no spaces are added.
     * @return The converted hex string. "null" if the byte array is null, and an empty string if the length is 0.
     */
    public static String toHexString( byte[] aByteArray, 
                                      int    aSpacingBase ) throws Exception
    {
        return toHexString(aByteArray, aSpacingBase, " ");
    }

    /**
     * Converts a byte array to a hex string.
     *
     * @param aByteArray The byte array to convert to a hex string
     * @param aAppendingBase The unit to insert aAppendingChar. If 0, do not append.
     * @param aAppendingString The string to append for each aAppendingBase
     * @return The converted hex string. "null" if the byte array is null, and an empty string if the length is 0.
     */
    public static String toHexString( byte[]    aByteArray, 
                                      int       aAppendingBase,
                                      String    aAppendingString ) throws Exception
    {
        return toHexString( aByteArray, 0, 0, aAppendingBase, aAppendingString, false);
    }

    /**
     * Converts a byte array to a hex string.
     *
     * @param aByteArray The byte array to be converted to a hex string
     * @param aStartIdx The first index (inclusive)
     * @param aEndIdx The last index (exclusive)
     * @param aAppendingBase The unit to insert aAppendingChar. If 0, do not append.
     * @param aAppendingString The string to append for each aAppendingBase
     * @param aToUpper Whether to convert to uppercase
     * @return The converted hex string. Returns "null" if the byte array is null, or an empty string if the length is 0.
     * @exception IllegalArgumentException If the argument is invalid
     */
    public static String toHexString( byte[] aByteArray, 
                                      int    aStartIdx,
                                      int    aEndIdx, 
                                      int    aAppendingBase, 
                                      String aAppendingString, 
                                      boolean aToUpper ) throws Exception
    {
        String sExString = null;
        
        if (aByteArray == null)
        {
            return "null";
        }
        if (aByteArray.length == 0)
        {
            return "";
        }
        if (aEndIdx == 0)
        {
            aEndIdx = aByteArray.length;
        }
        if (aEndIdx == aStartIdx)
        {
            return "";
        }
        
        if (aStartIdx < 0)
        {
            sExString = new String( "Start index [" + Integer.toString(aStartIdx) + "] " +
                                    "should be between 0 and Integer.MAX_VALUE" );
            throw new Exception( sExString );
        }
        
        if (aEndIdx < aStartIdx || aByteArray.length < aEndIdx)
        {
           sExString = new String( "End index [" + Integer.toString( aEndIdx )+"] " + 
                                   "should be between " + Integer.toString( aStartIdx ) + 
                                   "and " + Integer.toString( aByteArray.length ) );

            throw new Exception( sExString );
        }

        int sBufSize = (aEndIdx - aStartIdx) * 2;
        
        if (aAppendingString == null)
        {
            aAppendingBase = 0;
        }
        else if (aAppendingBase > 0)
        {
            sBufSize += (aByteArray.length % aAppendingBase) * aAppendingString.length();
        }

        final char[] HEX_LITERALS = aToUpper ? HEX_LITERALS_U : HEX_LITERALS_L;
        StringBuffer sBuf = new StringBuffer(sBufSize);
        for (int i = aStartIdx; i < aEndIdx; i++)
        {
            if ((aAppendingBase > 0) && (i > 0) && (i % aAppendingBase == 0))
            {
                sBuf.append(aAppendingString);
            }
            sBuf.append(HEX_LITERALS[(aByteArray[i] & 0xF0) >>> 4]);
            sBuf.append(HEX_LITERALS[(aByteArray[i] & 0x0F)]);
        }
        return sBuf.toString();
    }

    /**
     * Converts a ByteBuffer to a hex string.
     *
     * @param aByteArray ByteBuffer to be converted to a hex string
     * @return The converted hex string. "null" if the byte array is null, an empty string if the length is 0.
     */
    public static String toHexString(ByteBuffer mByteBuffer) throws Exception
    {
        if (mByteBuffer == null)
        {
            return "null";
        }
        return toHexString(mByteBuffer, 0, mByteBuffer.remaining());
    }

    /**
     * Converts a ByteBuffer to a hex string.
     *
     * @param aByteArray ByteBuffer to be converted to a hex string
     * @param aStartIdx First index (inclusive)
     * @param aEndIdx Last index (exclusive)
     * @return Converted hex string. Returns "null" if the byte array is null, and an empty string if the length is 0.
     */
    public static String toHexString( ByteBuffer mByteBuffer, 
                                      int        aStartIdx,
                                      int        aEndIdx) throws Exception
    {
        if (mByteBuffer == null)
        {
            return "null";
        }
        if (mByteBuffer.remaining() == 0)
        {
            return "";
        }

        if (mByteBuffer.hasArray())
        {
            return toHexString(mByteBuffer.array(), mByteBuffer.position() + aStartIdx, mByteBuffer.position() + aEndIdx);
        }
        else
        {
            byte[] sBuf = new byte[mByteBuffer.remaining()];
            int sOrgPos = mByteBuffer.position();
            mByteBuffer.get(sBuf);
            mByteBuffer.position(sOrgPos);
            return toHexString(sBuf, aStartIdx, aEndIdx);
        }
    }
}
