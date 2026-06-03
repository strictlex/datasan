/*set define off;*/
Create or replace and compile java source named OraSQL as

import java.math.BigInteger;
import java.nio.ByteBuffer;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.sql.*;

public class OraSQL {

    public static void main(String[] args) {
    }
    static final String date_1_1 = "2009-04-26 00:00:00";
    static final String date_1_2 = "2004-04-26 00:00:00";
    static final String date_1_3 = "1979-04-26 00:00:00";
    static final String date_3_1 = "2014-01-01 00:00:00";
    static final String date_3_2 = "2006-03-01 00:00:00";
    static final String date_3_3 = "2000-06-01 00:00:00";
    static final String nullDate = "1970-09-01 00:00:00";
    static final String lastDate = "2007-12-30 00:00:00";
    static  Timestamp minDate = Timestamp.valueOf(nullDate);
    static  Timestamp dateDiffer = Timestamp.valueOf(lastDate);
    static  Timestamp date_2_1 = Timestamp.valueOf(date_1_1);
    static  Timestamp date_2_2 = Timestamp.valueOf(date_1_2);
    static  Timestamp date_2_3 = Timestamp.valueOf(date_1_3);
    static  Timestamp date_4_1 = Timestamp.valueOf(date_3_1);
    static  Timestamp date_4_2 = Timestamp.valueOf(date_3_2);
    static  Timestamp date_4_3 = Timestamp.valueOf(date_3_3);

public OraSQL()
    {

    }
    public static byte[] ComputeHash(byte[] input)
    {
        long h = hash64(input, input.length);
        ByteBuffer buffer = ByteBuffer.allocate(Long.BYTES);
        buffer.putLong(h);
return buffer.array();
}
    public static long hash64(final byte[] data, int length, int seed) {
        final long m = 0xc6a4a7935bd1e995L;
        final int r = 47;

        long h = (seed&0xffffffffl)^(length*m);

int length8 = length/8;

for (int i=0; i<length8; i++) {
            final int i8 = i*8;
            long k =  ((long)data[i8+0]&0xff)      +(((long)data[i8+1]&0xff)<<8)
                    +(((long)data[i8+2]&0xff)<<16) +(((long)data[i8+3]&0xff)<<24)
                    +(((long)data[i8+4]&0xff)<<32) +(((long)data[i8+5]&0xff)<<40)
                    +(((long)data[i8+6]&0xff)<<48) +(((long)data[i8+7]&0xff)<<56);

            k *= m;
            k ^= k >>> r;
            k *= m;

            h ^= k;
            h *= m;
}

        switch (length%8) {
            case 7: h ^= (long)(data[(length&~7)+6]&0xff) << 48;
case 6: h ^= (long)(data[(length&~7)+5]&0xff) << 40;
case 5: h ^= (long)(data[(length&~7)+4]&0xff) << 32;
case 4: h ^= (long)(data[(length&~7)+3]&0xff) << 24;
case 3: h ^= (long)(data[(length&~7)+2]&0xff) << 16;
case 2: h ^= (long)(data[(length&~7)+1]&0xff) << 8;
case 1: h ^= (long)(data[length&~7]&0xff);
                h *= m;
};

        h ^= h >>> r;
        h *= m;
        h ^= h >>> r;

return h;
}

    /**
     * Generates 64 bit hash from byte array with default seed value.
     *
     * @param data byte array to hash
     * @param length length of the array to hash
     * @return 64 bit hash of the given string
     */
    public static long hash64(final byte[] data, int length) {
        return hash64(data, length, 0xe17a1465);
}


    public static Timestamp addDaysToTimestamp(Timestamp start, Double days) {
        return new Timestamp(start.getTime() + ((int) (24L * 60L * 60L * 1000L * days)));
}
    public static String EncodeHashFill(String s, String md) {
        if (s == null) {
            return null;
}
        byte[] bytes = s.getBytes();
        byte[] hash = ComputeHash(bytes);
int did = 0;
for (int i = 0; i < hash.length; i++) {
            did = did + ((int)((((int)(hash[i % hash.length]) % (10))))*(int)(Math.pow(10, i)));
}
        did = Math.abs(did % Integer.parseInt(md));
        String val = String.valueOf(did);
return val;
}
    public static String EncodeHashChar(String s) {
        if (s == null) {
            return null;
}
        byte[] bytes = s.getBytes();
        byte[] hash = ComputeHash(bytes);

char[] ca = s.toCharArray();

for (int i = 0; i < ca.length; i++) {
            if (1072 <= ca[i] && ca[i] <= 1103) {
                ca[i] = (char) (1072 + Math.abs(((int)(hash[i % hash.length] + ca[i]) % (32))));
} else if (1040 <= ca[i] && ca[i] <= 1071) {
                ca[i] = (char) (1040 + Math.abs(((int)(hash[i % hash.length] + ca[i]) % (32))));
} else if ('0' <= ca[i] && ca[i] <= '9') {
                ca[i] = (char) ('0' + Math.abs(((int)(hash[i % hash.length] + ca[i]) % (10))));
} else if ('a' <= ca[i] && ca[i] <= 'z') {
                ca[i] = (char) ('a' + Math.abs(((int)(hash[i % hash.length] + ca[i]) % (26))));
} else if ('A' <= ca[i] && ca[i] <= 'Z') {
                ca[i] = (char) ('A' + Math.abs(((int)(hash[i % hash.length] + ca[i]) % (26))));
}
        }
        return new String(ca);
}

    public static String EncodeHashCharDel(String s) {
        if (s == null) {
            return null;
}
        char[] ca = s.toCharArray();
        String fstr= "";
        String tstr= " ";
        String sstr = s;
int strst;
int strend;
        strst = 0;
for (int i = 0; i < ca.length; i++) {
            if (ca[i] == ' ') {
                strend=i;
                fstr=fstr.concat(EncodeHashChar(s.substring(strst,strend))).concat(tstr);
                strst=i+1;
}
        }

        strend=ca.length;
        fstr=fstr.concat(EncodeHashChar(sstr.substring(strst,strend)));

return new String(fstr);
}
    public static String EncodeHashCharPassport(String s) {
        if (s == null) {
            return null;
}

        char[] ca = s.toCharArray();
        String fstr= "";
        String tstr= " ";
        String sstr = s;
int strst;
int strend;
        strst = 0;
        if ('0' <= ca[0] && ca[0] <= '9')
        {
            if (ca.length==4 || ca.length==6) {
                fstr=EncodeHashCharDel(s);
}
            else if (ca.length==5)
            {
                fstr=fstr.concat(s.substring(0,2)).concat(s.substring(3,5));
                fstr=EncodeHashChar(fstr);
                fstr=(fstr.substring(0,2)).concat(tstr).concat(fstr.substring(2,4));
}
            else if (ca.length==12)
            {
                if (ca[2] == ' ') {
                    fstr=EncodeHashChar(fstr.concat(s.substring(0,2)).concat(s.substring(3,5))).concat(tstr).concat(EncodeHashChar(s.substring(6,12)));
                    fstr=(fstr.substring(0,2)).concat(tstr).concat(fstr.substring(2,11));
} else if (ca[6] == ' ')
                {
                    fstr=EncodeHashChar(s.substring(0,6)).concat(tstr).concat(EncodeHashChar(fstr.concat(s.substring(7,9)).concat(s.substring(10,12))));
                    fstr=(fstr.substring(0,9)).concat(tstr).concat(fstr.substring(9,11));
}
            }
            else
            {
                fstr=EncodeHashCharDel(s);
}
        }
        return new String(fstr);
}
    public static String EncodeHashCharFirm(String s) {
        if (s == null) {
            return null;
}

        char[] ca = s.toCharArray();
        String fstr= "";
        String tstr= " ";
        String sstr = s;
int strst;
int strend;
        strst = 0;

for (int i = 0; i < ca.length; i++) {





            if (ca[i] == ' ') {
                strend=i;
                if (strend<4) {
                    fstr=(s.substring(strst,strend)).concat(tstr).concat(EncodeHashChar(s.substring(strend+1,ca.length)));
return new String(fstr);
}
                else

                {
                    fstr=EncodeHashChar(s);
return new String(fstr);
}

            }
        }
        fstr=EncodeHashChar(s);
return new String(fstr);
}

    public static String EncodeHashCharPhone(String s) {
        if (s == null) {
            return null;
}

        char[] ca = s.toCharArray();
        String fstr= "";
        String tstr= " ";
int strst;
int strend;
        strst = 0;
        if (ca.length<4) {
            fstr=EncodeHashChar(s);
return new String(fstr);
}
        if (ca[0] == '+') {
            fstr=(s.substring(0,3)).concat(EncodeHashChar(s.substring(3,ca.length)));
return new String(fstr);
}
        else
        {
            fstr=(s.substring(0,2)).concat(EncodeHashChar(s.substring(2,ca.length)));
return new String(fstr);
}
    }

    public static byte[] EncodeHashBinary(byte[] b) {
        if (b == null) {
            return null;
}
        byte[] md5hash = ComputeHash(b);

for (int i = 0; i < b.length; i++) {
            b[i] = md5hash[i % md5hash.length];
}
        return b;
}


    public static Timestamp EncodeHashDate(java.sql.Timestamp dt) {
        String deb = null;
        java.sql.Timestamp ts = null;
        if (dt == null) {
            ts = minDate;
            deb = Long.toString(minDate.getTime());
}
        String str = Long.toString(dt.getTime());
        str = EncodeHashChar(str);
        ts=new Timestamp((long)(minDate.getTime() + (Long.parseLong(str,10)) % dateDiffer.getTime()));
return ts;

}
    public static Timestamp EncodeHashBDate(java.sql.Timestamp dt) {
        String deb = null;
        java.sql.Timestamp ts = null;
        if (dt == null) {
            return dt;
}
        if (dt.after(date_2_1))
        {
            ts=date_4_1;
}
        else if (dt.after(date_2_2))
        {
            ts=date_4_2;
}
        else if (dt.after(date_2_3))
        {
            ts=date_4_3;
}
        else
        {
            ts=minDate;
}
        return ts;

}

    public static Timestamp EncodeHashCDate(java.sql.Timestamp dt) {
        String deb = null;
        java.sql.Timestamp ts = null;
        java.sql.Timestamp tinter = null;
        Calendar cal = Calendar.getInstance();
        if (dt == null) {
            return dt;
}
        else
        {
            ts= dt;
            cal.setTimeInMillis(ts.getTime());
            cal.add(Calendar.MONTH, -14);
            tinter = new Timestamp(cal.getTime().getTime());
}
        ts= dt;
        String str = Long.toString(dt.getTime());
        str = EncodeHashChar(str);
        ts=new Timestamp((long)(tinter.getTime() + (Long.parseLong(str,10)) % (ts.getTime()-tinter.getTime())));
return ts;

}

    public static String EncodeHashCharInn(String s) {
        if (s == null) {
            return null;
}
        String str=null;
int length = s.length();
        if (s.length() < 10 || s.length() == 11 || s.length() > 12) {
            str = EncodeHashChar(s);
return str;
}
        char[] resChar = new char[length];

int[] ia = new int[length];


        byte[] bytes = s.getBytes();
        byte[] hash = ComputeHash(bytes);
int offsetValue;
        if (s.length() == 10) {
            for (int i = 0; i < 10; i++) {
                offsetValue = Math.abs(((int)(hash[i % hash.length] + ia[i]) % (10)));
                resChar[i] = (char) ('0' + offsetValue);
                ia[i] = offsetValue;
}
            resChar[9] = Integer.toString(((2*ia[0] + 4*ia[1] + 10*ia[2] + 3*ia[3] + 5*ia[4] + 9*ia[5] + 4*ia[6] + 6*ia[7] + 8*ia[8]) % 11) % 10).charAt(0);
} else if (s.length() == 12) {
            for (int i = 0; i < 11; i++) {
                offsetValue = Math.abs(((int)(hash[i % hash.length] + ia[i]) % (10)));
                resChar[i] = (char) ('0' + offsetValue);
                ia[i] = offsetValue;
}
            ia[10] = (((7*ia[0] +  2*ia[1] +  4*ia[2] +  10*ia[3] +  3*ia[4] +  5*ia[5] +  9*ia[6] +  4*ia[7] +  6*ia[8] +  8*ia[9]) % 11) % 10);
            resChar[10] = Integer.toString(ia[10]).charAt(0);
            resChar[11] = Integer.toString(((3*ia[0] +  7*ia[1] +  2*ia[2] +  4*ia[3] +  10*ia[4] +  3*ia[5] +  5*ia[6] +  9*ia[7] +  4*ia[8] +  6*ia[9] +  8*ia[10]) % 11) % 10).charAt(0);
}
        return new String(resChar);
}

    public static String EncodeHashCharSnils(String s) {
        if (s == null) {
            return null;
}
        String str=null;
int knum = 0;
int length = s.length();
        if (s.length() < 11 || s.length() > 11) {
            str = EncodeHashChar(s);
return str;
}
        char[] resChar = new char[length];

int[] ia = new int[length];

        byte[] bytes = s.getBytes();
        byte[] hash = ComputeHash(bytes);
int offsetValue;
        if (s.length() == 11) {
            for (int i = 0; i < 10; i++) {
                offsetValue = Math.abs(((int)(hash[i % hash.length] + ia[i]) % (10)));
                resChar[i] = (char) ('0' + offsetValue);
                ia[i] = offsetValue;
}
            knum = (9*ia[0] + 8*ia[1] + 7*ia[2] + 6*ia[3] + 5*ia[4] + 4*ia[5] + 3*ia[6] + 2*ia[7] + 1*ia[8]);
            knum = knum % 101;
            if (knum == 100) {
                resChar[9] = "0".charAt(0);
                resChar[10] = "0".charAt(0);
}
            else if (knum>9)
            {
                resChar[9] = Integer.toString(knum).charAt(0);
                resChar[10] = Integer.toString(knum).charAt(1);
}
            else
            {
                resChar[9] = "0".charAt(0);
                resChar[10] = Integer.toString(knum).charAt(0);
}

        }
        return new String(resChar);
}

    public static String EncodeHashCharOgrn(String s) {
        if (s == null) {
            return null;
}
        int length = s.length();

char[] resChar = new char[length];
int[] ia = new int[length];


        byte[] bytes = s.getBytes();
        byte[] hash = ComputeHash(bytes);


        long ogrn = 0;
int offsetValue;
        if (s.length() == 13) {
            for (int i = 0; i < 12; i++) {
                offsetValue = Math.abs(((int)(hash[i % hash.length] + ia[i]) % (10)));
                resChar[i] = (char) ('0' + offsetValue);
                ogrn = 10*ogrn + offsetValue;
}
            resChar[12] = Long.toString((ogrn % 11) % 10).charAt(0);
}
        else if (s.length() == 15) {
            for (int i = 0; i < 14; i++) {
                offsetValue = Math.abs(((int)(hash[i % hash.length] + ia[i]) % (10)));
                resChar[i] = (char) ('0' + offsetValue);
                ogrn = 10*ogrn + offsetValue;
}
            resChar[14] = Long.toString((ogrn % 13) % 10).charAt(0);
}
        else
        {
            return EncodeHashChar(s);
}

        return new String(resChar);
}
    public static Integer EncodeHashID250(String s) {
        if (s == null) {
            return null;
}
        String str=null;
int knum = 0;

        byte[] bytes = s.getBytes();
        byte[] hash = ComputeHash(bytes);
int offsetValue;
        offsetValue = Math.abs((int)(hash[1 % hash.length] % (250)));
return offsetValue;
}

    public static Integer EncodeHashDateCheckD(java.sql.Date dt) {
        if (dt == null) {
            return null;
}
        String str=null;
int knum = 0;
        String s;
        s=dt.toString();
        byte[] bytes = s.getBytes();
        byte[] hash = ComputeHash(bytes);
int offsetValue;
        offsetValue = Math.abs((int)(hash[1 % hash.length] % (250)));
return offsetValue;
}


}
;
/ --HARDCODE FOR DEPLOYMENT
Create or replace java source named Adresses as

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

public class Adresses {
    public static HashMap <String, String> shuffledValues = new HashMap<>();
    static String[] delimiters = {";","г.", "ул.", "д.", ",", "г ", "ул  ", "д ", "с ", "с.", "Г.", "УЛ.", "Д.", ",", "Г ", "УЛ ", "Д ", "С ", "С."};
public static void fillAndShuffle(java.sql.Clob value, String keyword) throws SQLException {
        String strValue = value.getSubString(1, (int) value.length());
        String[] parts = strValue.split(";");

        List<String> nonEmptyList = new ArrayList<>();
for (String s : parts) {
            if (!s.trim().isEmpty()) {
                nonEmptyList.add(s.trim());
}
        }

        String[] words = nonEmptyList.toArray(new String[0]);
        String[] arr = words.clone();
        byte[] bytes = ComputeHash(keyword.getBytes());
for(int j = words.length - 1; j >= 1; j--){
                int index = (bytes[0 % bytes.length] & 0xFF) % (j);
                String temp = arr[index];
                arr[index] = arr[j];
                arr[j] = temp;
        }
        for(int i = 0; i < words.length; i++){
            shuffledValues.put(arr[i].toUpperCase(), words[i].toUpperCase());
        }
    }
    public static String getValue(String value){
        if (value == null)
            return null;
        String regex = createRegex();
        String[] tokens = value.split(createRegexForDelimiters());
        StringBuilder result = new StringBuilder();
        for (String token : tokens) {
            if (token.matches(regex)) {
                result.append(token);
            } else {
                String replacement = shuffledValues.get(
                        token.trim().toUpperCase()
                );
                if(replacement == null) {
                    int lastSpaceIndex = token.lastIndexOf(' ');
                    if (lastSpaceIndex != -1) {
                        String beforeLastSpace = token.substring(0, lastSpaceIndex);
                        String appender = shuffledValues.get(
                                beforeLastSpace.trim().toUpperCase()
                        );
                        if(appender != null){
                            result.append(token.replace(beforeLastSpace.trim(), format(appender, beforeLastSpace.trim())));
                            continue;
                        }
                    }
                    result.append(OraSQL.EncodeHashChar(token));

                }
                else
                    result.append(token.replace(token.trim(), format(replacement, token.trim())));
            }
        }
        return result.toString();
    }

    static String format(String word, String form){
        if(Character.isLowerCase(form.charAt(0)))
            return word.toLowerCase();
        if(word.length() > 1 && form.length() > 1 && Character.isLowerCase(form.charAt(1)))
            return Character.toUpperCase(word.charAt(0)) + word.substring(1).toLowerCase();
        return word.toUpperCase();
    }

    private static String createRegex(){
        StringBuilder result = new StringBuilder();
        for (String delimiter : delimiters) {
            if (result.length() > 0) result.append("|");
            result.append(Pattern.quote(delimiter));
        }
        return result.toString();
    }
    private static String createRegexForDelimiters(){
        StringBuilder result = new StringBuilder();
        for (String delimiter : delimiters) {
            if (result.length() > 0) result.append("|");
            result.append("(?<=");
            result.append(Pattern.quote(delimiter));
            result.append(")|(?=");
            result.append(Pattern.quote(delimiter));
            result.append(")");
        }
        return result.toString();
    }
    public static byte[] ComputeHash(byte[] input)
    {
        try {

            MessageDigest md = MessageDigest.getInstance("MD5");
            return md.digest(input);
        }

        catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }
}
;
/ --HARDCODE FOR DEPLOYMENT
create or replace and compile java source named FamDict as

import java.sql.Clob;
import java.util.ArrayList;
import java.util.HashMap;

public class FamDict {
    public static ArrayList<String> cyrillicNames = new ArrayList<>();
    public static ArrayList<String> latinNames = new ArrayList<>();
    public static HashMap<String, String> dict = new HashMap<>();
    public static void AddNames(Clob names){
        try {
            String val = names.getSubString(1, (int)names.length());
            ClearNames();
            String tmp[] = val.split(";");
            for(String name : tmp){
                AddName(name);
            }
            ArraysShuffle("abc", 20);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
    public static void AddName(String name){
        if(name.length() == 0)
            return;
        if((name.charAt(0) >= 'a' && name.charAt(0) <= 'z') ||
                (name.charAt(0) >= 'A' && name.charAt(0) <= 'Z'))
            latinNames.add(name.toLowerCase());
        if((name.charAt(0) >= 'а' && name.charAt(0) <= 'я') ||
                (name.charAt(0) >= 'А' && name.charAt(0) <= 'Я'))
            cyrillicNames.add(name.toLowerCase());
    }
    public static void ClearNames(){
        cyrillicNames.clear();
        latinNames.clear();
        dict.clear();
    }
    public static void ArraysShuffle(String shuffleKey, int range){
        dict.clear();
        ArrayShuffle(cyrillicNames, shuffleKey, range);
        ArrayShuffle(latinNames, shuffleKey, range);
    }
    public static void ArrayShuffle(ArrayList<String> names, String shuffleKey, int range){
        byte[] bytes = OraSQL.ComputeHash(shuffleKey.getBytes());
        String[] arr = new String[names.size()];
        int deep = (names.size() * range + 99) / 100;
        for(int i = 0; i < names.size(); i++)
            arr[i] = names.get(i);
        for(int i = 0; i < names.size(); i+=deep){
            for(int j = Math.min(i + deep -  1, names.size() - 1); j >= i ; j--){
                int index = (bytes[i % bytes.length] & 0xFF) % (j - i + 1) + i;
                String temp = arr[index];
                arr[index] = arr[j];
                arr[j] = temp;
            }
        }
        for(int i  = 0; i < names.size(); i++) {
            dict.put(names.get(i), arr[i]);
        }
    }
    public static String GetFamWithLength(String key,int maxLength){
        String name = GetName(key);
  if(name != null && name.length() > maxLength){
      return name.substring(0,maxLength);
        }
    return name;
    }

    public static String GetName(String key){
        if (key == null)
            return null;
        if (dict.containsKey(key.toLowerCase()))
            return Format(dict.get(key.toLowerCase()), key);
        else
            return OraSQL.EncodeHashChar(key);
    }
    public static String GetFamWithLen(String key, int maxLength) {
    String name = GetName(key);
    if (name != null && name.length() > maxLength)
        return name.substring(0, maxLength);
    else

    return name;
    }
    static String Format(String word, String format){
        if(Character.isLowerCase(format.charAt(0)))
            return word.toLowerCase();
        if(word.length() > 1 && Character.isLowerCase(format.charAt(1)))
            return Character.toUpperCase(word.charAt(0)) + word.substring(1).toLowerCase();
        return word.toUpperCase();
    }
}
;
/ --HARDCODE FOR DEPLOYMENT
create or replace and compile java source named NameDict as

import java.sql.Clob;
import java.util.ArrayList;
import java.util.HashMap;

public class NameDict {
    public static ArrayList<String> cyrillicNames = new ArrayList<>();
    public static ArrayList<String> latinNames = new ArrayList<>();
    public static HashMap<String, String> dict = new HashMap<>();
    public static void AddNames(Clob names){
        try {
            String val = names.getSubString(1, (int)names.length());
            ClearNames();
            String tmp[] = val.split(";");
            for(String name : tmp){
                AddName(name);
            }
            ArraysShuffle("abc", 20);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
    public static void AddName(String name){
        if(name.length() == 0)
            return;
        if((name.charAt(0) >= 'a' && name.charAt(0) <= 'z') ||
                (name.charAt(0) >= 'A' && name.charAt(0) <= 'Z'))
            latinNames.add(name.toLowerCase());
        if((name.charAt(0) >= 'а' && name.charAt(0) <= 'я') ||
                (name.charAt(0) >= 'А' && name.charAt(0) <= 'Я'))
            cyrillicNames.add(name.toLowerCase());
    }
    public static void ClearNames(){
        cyrillicNames.clear();
        latinNames.clear();
        dict.clear();
    }
    public static void ArraysShuffle(String shuffleKey, int range){
        dict.clear();
        ArrayShuffle(cyrillicNames, shuffleKey, range);
        ArrayShuffle(latinNames, shuffleKey, range);
    }
    public static void ArrayShuffle(ArrayList<String> names, String shuffleKey, int range){
        byte[] bytes = OraSQL.ComputeHash(shuffleKey.getBytes());
        String[] arr = new String[names.size()];
        int deep = (names.size() * range + 99) / 100;
        for(int i = 0; i < names.size(); i++)
            arr[i] = names.get(i);
        for(int i = 0; i < names.size(); i+=deep){
            for(int j = Math.min(i + deep -  1, names.size() - 1); j >= i ; j--){
                int index = (bytes[i % bytes.length] & 0xFF) % (j - i + 1) + i;
                String temp = arr[index];
                arr[index] = arr[j];
                arr[j] = temp;
            }
        }
        for(int i  = 0; i < names.size(); i++) {
            dict.put(names.get(i), arr[i]);
        }
    }
    public static String GetNameWithLen(String key,int maxLength){
        String name = GetName(key);
  if(name != null && name.length() > maxLength){
      return name.substring(0,maxLength);
        }
    return name;
    }

    public static String GetName(String key){
        if (key == null)
            return null;
        if (dict.containsKey(key.toLowerCase()))
            return Format(dict.get(key.toLowerCase()), key);
        else
            return OraSQL.EncodeHashChar(key);
    }
    public static String GetFamWithLen(String key, int maxLength) {
    String name = GetName(key);
    if (name != null && name.length() > maxLength)
        return name.substring(0, maxLength);
    else

    return name;
    }
    static String Format(String word, String format){
        if(Character.isLowerCase(format.charAt(0)))
            return word.toLowerCase();
        if(word.length() > 1 && Character.isLowerCase(format.charAt(1)))
            return Character.toUpperCase(word.charAt(0)) + word.substring(1).toLowerCase();
        return word.toUpperCase();
    }
}

;
/ --HARDCODE FOR DEPLOYMENT
create or replace and compile java source named OtchDict as

import java.sql.Clob;
import java.util.ArrayList;
import java.util.HashMap;

public class OtchDict {
    public static ArrayList<String> cyrillicNames = new ArrayList<>();
    public static ArrayList<String> latinNames = new ArrayList<>();
    public static HashMap<String, String> dict = new HashMap<>();
    public static void AddNames(Clob names){
        try {
            String val = names.getSubString(1, (int)names.length());
            ClearNames();
            String tmp[] = val.split(";");
            for(String name : tmp){
                AddName(name);
            }
            ArraysShuffle("abc", 20);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
    public static void AddName(String name){
        if(name.length() == 0)
            return;
        if((name.charAt(0) >= 'a' && name.charAt(0) <= 'z') ||
                (name.charAt(0) >= 'A' && name.charAt(0) <= 'Z'))
            latinNames.add(name.toLowerCase());
        if((name.charAt(0) >= 'а' && name.charAt(0) <= 'я') ||
                (name.charAt(0) >= 'А' && name.charAt(0) <= 'Я'))
            cyrillicNames.add(name.toLowerCase());
    }
    public static void ClearNames(){
        cyrillicNames.clear();
        latinNames.clear();
        dict.clear();
    }
    public static void ArraysShuffle(String shuffleKey, int range){
        dict.clear();
        ArrayShuffle(cyrillicNames, shuffleKey, range);
        ArrayShuffle(latinNames, shuffleKey, range);
    }
    public static void ArrayShuffle(ArrayList<String> names, String shuffleKey, int range){
        byte[] bytes = OraSQL.ComputeHash(shuffleKey.getBytes());
        String[] arr = new String[names.size()];
        int deep = (names.size() * range + 99) / 100;
        for(int i = 0; i < names.size(); i++)
            arr[i] = names.get(i);
        for(int i = 0; i < names.size(); i+=deep){
            for(int j = Math.min(i + deep -  1, names.size() - 1); j >= i ; j--){
                int index = (bytes[i % bytes.length] & 0xFF) % (j - i + 1) + i;
                String temp = arr[index];
                arr[index] = arr[j];
                arr[j] = temp;
            }
        }
        for(int i  = 0; i < names.size(); i++) {
            dict.put(names.get(i), arr[i]);
        }
    }
    public static String GetOtchWithLen(String key,int maxLength){
        String name = GetName(key);
  if(name != null && name.length() > maxLength){
      return name.substring(0,maxLength);
        }
    return name;
    }

    public static String GetName(String key){
        if (key == null)
            return null;
        if (dict.containsKey(key.toLowerCase()))
            return Format(dict.get(key.toLowerCase()), key);
        else
            return OraSQL.EncodeHashChar(key);
    }
    public static String GetFamWithLen(String key, int maxLength) {
    String name = GetName(key);
    if (name != null && name.length() > maxLength)
        return name.substring(0, maxLength);
    else

    return name;
    }
    static String Format(String word, String format){
        if(Character.isLowerCase(format.charAt(0)))
            return word.toLowerCase();
        if(word.length() > 1 && Character.isLowerCase(format.charAt(1)))
            return Character.toUpperCase(word.charAt(0)) + word.substring(1).toLowerCase();
        return word.toUpperCase();
    }
}
;
/ --HARDCODE FOR DEPLOYMENT
create or replace and compile java source named FIODict as

import java.util.*;
import java.util.stream.Stream;
import static java.util.Collections.swap;

public class FIODict {



    public static String GetFioWithLen(String key,int maxLength){
            String name = GetFio(key);
	    if(name != null && name.length() > maxLength){
	       return name.substring(0,maxLength);
            }
            return name;
        }

    public static String GetFio(String fio) {
        if (fio == null)
            return null;
        String[] words = fio.split("\\s+");
        return GetValue(words);
    }
    public static String GetValue(String[] words){
        StringBuilder result = new StringBuilder();
        for(String word : words){
            if(NameDict.dict.containsKey(word.toLowerCase())){
                result.append(NameDict.Format(NameDict.dict.get(word.toLowerCase()), word) + " ");
                continue;
            }

            if(FamDict.dict.containsKey(word.toLowerCase())){
                result.append(FamDict.Format(FamDict.dict.get(word.toLowerCase()), word) + " ");
                continue;
            }

            if(OtchDict.dict.containsKey(word.toLowerCase())){
                result.append(OtchDict.Format(OtchDict.dict.get(word.toLowerCase()), word) + " ");
                continue;
            }
            result.append(OraSQL.EncodeHashChar(word) + " ");
        }
        return result.toString();
    }
}
;
/ --HARDCODE FOR DEPLOYMENT
CREATE OR REPLACE AND COMPILE JAVA SOURCE NAMED "depers_by_dict" AS
import java.sql.Clob;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.StringTokenizer;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Pattern;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

public class depers_by_dict {

    // Сессионное хранилище: ключ = "SID:SESSIONID", значение = карты словарей текущей сессии
    private static final Map<String, Map<Integer, AnonymizerDictionary>> sessionDictionaries = new ConcurrentHashMap<>();
    // Регулярное выражение для проверки идентификаторов схем/таблиц
    private static final Pattern IDENTIFIER_PATTERN = Pattern.compile("[A-Za-z0-9_#$]+");

    // Конфигурация, когда делимитеры отключены
    private static final DelimiterConfig DELIMITERS_DISABLED = new DelimiterConfig(false, Collections.emptyList());

    // Описание словаря в памяти
    private static class AnonymizerDictionary {
        int id;                               // ID словаря
        String name;                          // Имя словаря
        List<String> originalValues = new ArrayList<>();   // исходные значения
        List<String> anonymizedValues = new ArrayList<>(); // перемешанные значения
        Map<String, String> pairMap = new HashMap<>();     // карта "исходное -> анонимизированное"
        long loadTimestamp;                   // момент загрузки (для статистики)
    }

    private static class DelimiterConfig {
        final boolean enabled;
        final List<Delimiter> delimiters;

        DelimiterConfig(boolean enabled, List<Delimiter> delimiters) {
            this.enabled = enabled;
            this.delimiters = delimiters;
        }
    }

    private static class Delimiter {
        final String value;
        final int length;

        Delimiter(String value) {
            this.value = value;
            this.length = value.length();
        }
    }

    private static class Token {
        String text;
        final boolean delimiter;

        Token(String text, boolean delimiter) {
            this.text = text;
            this.delimiter = delimiter;
        }
    }

    private static boolean isHashEnabled(String option) {
        if (option == null) {
            return false;
        }
        String normalized = option.trim();
        if (normalized.isEmpty()) {
            return false;
        }
        int eqIndex = normalized.indexOf('=');
        if (eqIndex >= 0) {
            normalized = normalized.substring(eqIndex + 1).trim();
        }
        if (normalized.equalsIgnoreCase("true")) return true;
        if (normalized.equalsIgnoreCase("yes")) return true;
        if (normalized.equalsIgnoreCase("on")) return true;
        if (normalized.equals("1")) return true;
        return false;
    }

    private static int parseMaxLength(String option) {
        if (option == null) {
            return -1;
        }
        String normalized = option.trim();
        if (normalized.isEmpty()) {
            return -1;
        }
        int eqIndex = normalized.indexOf('=');
        if (eqIndex >= 0) {
            normalized = normalized.substring(eqIndex + 1).trim();
        }
        if (normalized.isEmpty()) {
            return -1;
        }
        if (normalized.equalsIgnoreCase("false") || normalized.equalsIgnoreCase("off")
                || normalized.equalsIgnoreCase("no") || normalized.equals("0")) {
            return -1;
        }
        try {
            int value = Integer.parseInt(normalized);
            return value > 0 ? value : -1;
        } catch (NumberFormatException ex) {
            return -1;
        }
    }

    private static String applyMaxLength(String value, int maxLength) {
        if (value == null) {
            return null;
        }
        if (maxLength > 0 && value.length() > maxLength) {
            if (value.startsWith("ERROR:") || value.startsWith("WARNING:")) {
                return value;
            }
            return value.substring(0, maxLength);
        }
        return value;
    }

    private static byte[] ComputeHash(byte[] input) {
        try {
            MessageDigest md = MessageDigest.getInstance("MD5");
            return md.digest(input);
        } catch (NoSuchAlgorithmException ex) {
            throw new RuntimeException(ex);
        }
    }

    private static String EncodeHashChar(String value) {
        if (value == null) {
            return null;
        }
        byte[] hash = ComputeHash(value.getBytes());
        char[] chars = value.toCharArray();
        for (int i = 0; i < chars.length; i++) {
            char c = chars[i];
            int h = hash[i % hash.length];
            if (c >= 'а' && c <= 'я') {
                chars[i] = (char) ('а' + Math.abs(h % 32));
            } else if (c >= 'А' && c <= 'Я') {
                chars[i] = (char) ('А' + Math.abs(h % 32));
            } else if (c >= '0' && c <= '9') {
                chars[i] = (char) ('0' + Math.abs(h % 10));
            } else if (c >= 'a' && c <= 'z') {
                chars[i] = (char) ('a' + Math.abs(h % 26));
            } else if (c >= 'A' && c <= 'Z') {
                chars[i] = (char) ('A' + Math.abs(h % 26));
            }
        }
        return new String(chars);
    }

    private static String hashValue(String value) {
        String hashed = EncodeHashChar(value);
        return hashed != null ? hashed : value;
    }

    // Соединение по умолчанию внутри Java stored procedure
    private static Connection getDefaultConnection() throws SQLException {
        return DriverManager.getConnection("jdbc:default:connection:");
    }

    // Возвращает уникальный ключ текущей сессии Oracle
    private static String getCurrentSessionKey() throws SQLException {
        Connection conn = getDefaultConnection();
        String sid = null;
        String serial = null;
        SQLException lastError = null;

        // Сначала пробуем получить SESSIONID (есть в 12c и новее)
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT SYS_CONTEXT('USERENV','SID'), SYS_CONTEXT('USERENV','SESSIONID') FROM dual")) {
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    sid = rs.getString(1);
                    serial = rs.getString(2);
                }
            }
        } catch (SQLException ex) {
            lastError = ex;
        }

        if (sid != null && serial != null) {
            return sid + ':' + serial;
        }

        if (lastError != null) {
            throw lastError;
        }
        throw new SQLException("Не удалось определить идентификатор сессии");
    }

    private static Map<Integer, AnonymizerDictionary> getSessionStore() throws SQLException {
        // Получаем словари текущей сессии, создаём контейнер при первом обращении
        String sessionKey = getCurrentSessionKey();
        sessionDictionaries.putIfAbsent(sessionKey, new ConcurrentHashMap<Integer, AnonymizerDictionary>());
        return sessionDictionaries.get(sessionKey);
    }

    private static String sanitizeAndUpper(String name) throws SQLException {
        // Проверяем имя таблицы/схемы и приводим к верхнему регистру
        if (name == null || name.trim().isEmpty()) {
            throw new SQLException("Имя таблицы не может быть пустым");
        }
        String trimmed = name.trim();
        if (trimmed.contains(".")) {
            String[] parts = trimmed.split("\\.", 2);
            if (!IDENTIFIER_PATTERN.matcher(parts[0]).matches() || !IDENTIFIER_PATTERN.matcher(parts[1]).matches()) {
                throw new SQLException("Имя таблицы содержит недопустимые символы");
            }
            return parts[0].toUpperCase(Locale.ROOT) + "." + parts[1].toUpperCase(Locale.ROOT);
        }
        if (!IDENTIFIER_PATTERN.matcher(trimmed).matches()) {
            throw new SQLException("Имя таблицы содержит недопустимые символы");
        }
        return trimmed.toUpperCase(Locale.ROOT);
    }

    private static String getCurrentSchema(Connection conn) throws SQLException {
        try (Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT SYS_CONTEXT('USERENV','CURRENT_SCHEMA') FROM dual")) {
            if (rs.next()) {
                return rs.getString(1);
            }
        }
        throw new SQLException("Не удалось определить схему");
    }

    private static TableRef resolveTableReference(String tableName) throws SQLException {
        // Разбираем имя таблицы: если схема не указана, подставляем текущую
        Connection conn = getDefaultConnection();
        String sanitized = sanitizeAndUpper(tableName);
        if (sanitized.contains(".")) {
            String[] parts = sanitized.split("\\.");
            return new TableRef(parts[0], parts[1]);
        }
        return new TableRef(getCurrentSchema(conn), sanitized);
    }

    private static String quoteIdentifier(String identifier) {
        // Обязательное экранирование, чтобы сохранить регистр и спецсимволы
        return "\"" + identifier.replace("\"", "\"\"") + "\"";
    }

    private static DelimiterConfig loadDelimiters(String tableName) throws SQLException {
        if (tableName == null) return DELIMITERS_DISABLED;
        String trimmed = tableName.trim();
        if (trimmed.isEmpty() || "false".equalsIgnoreCase(trimmed)) {
            return DELIMITERS_DISABLED;
        }

        TableRef table = resolveTableReference(trimmed);
        List<Delimiter> delimiters = new ArrayList<>();
        String sql = "SELECT " + quoteIdentifier("VALUE") + " FROM " + table.toSqlName()
                + " WHERE " + quoteIdentifier("VALUE") + " IS NOT NULL";

        Connection conn = getDefaultConnection();
        try (Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                String raw = rs.getString(1);
                if (raw == null) continue;
                String decoded = decodeDelimiter(raw);
                if (!decoded.isEmpty()) {
                    delimiters.add(new Delimiter(decoded));
                }
            }
        }

        if (delimiters.isEmpty()) {
            return DELIMITERS_DISABLED;
        }

        Collections.sort(delimiters, new Comparator<Delimiter>() {
            @Override
            public int compare(Delimiter a, Delimiter b) {
                return Integer.compare(b.length, a.length);
            }
        });
        return new DelimiterConfig(true, delimiters);
    }

    private static String decodeDelimiter(String value) {
        if (value == null || value.isEmpty()) {
            return "";
        }
        StringBuilder result = new StringBuilder();
        boolean escape = false;
        for (int i = 0; i < value.length(); i++) {
            char ch = value.charAt(i);
            if (escape) {
                switch (ch) {
                    case 'n': result.append('\n'); break;
                    case 'r': result.append('\r'); break;
                    case 't': result.append('\t'); break;
                    case 's': result.append(' '); break;
                    case 'p': result.append('.'); break;
                    case ',': result.append(','); break;
                    case '\\': result.append('\\'); break;
                    default: result.append(ch); break;
                }
                escape = false;
            } else if (ch == '\\') {
                escape = true;
            } else {
                result.append(ch);
            }
        }
        if (escape) {
            result.append('\\');
        }
        return result.toString();
    }

    private static List<Token> splitByDelimiters(String source, DelimiterConfig config) {
        List<Token> tokens = new ArrayList<>();
        if (source == null) {
            return tokens;
        }
        if (!config.enabled || source.isEmpty()) {
            tokens.add(new Token(source, false));
            return tokens;
        }

        int index = 0;
        int wordStart = 0;
        int length = source.length();

        while (index < length) {
            Delimiter match = findDelimiter(config.delimiters, source, index);
            if (match != null) {
                if (wordStart < index) {
                    String word = source.substring(wordStart, index);
                    if (!word.isEmpty()) {
                        tokens.add(new Token(word, false));
                    }
                }
                String delimiterText = source.substring(index, index + match.length);
                tokens.add(new Token(delimiterText, true));
                index += match.length;
                wordStart = index;
                continue;
            }
            index++;
        }

        if (wordStart < length) {
            String tail = source.substring(wordStart);
            if (!tail.isEmpty()) {
                tokens.add(new Token(tail, false));
            }
        }

        if (tokens.isEmpty()) {
            tokens.add(new Token(source, false));
        }
        return tokens;
    }

    private static Delimiter findDelimiter(List<Delimiter> delimiters, String source, int index) {
        int remaining = source.length() - index;
        for (Delimiter delimiter : delimiters) {
            if (delimiter.length > remaining) {
                continue;
            }
            if (source.regionMatches(true, index, delimiter.value, 0, delimiter.length)) {
                return delimiter;
            }
        }
        return null;
    }

    private static String joinTokens(List<Token> tokens) {
        StringBuilder sb = new StringBuilder();
        for (Token token : tokens) {
            sb.append(token.text);
        }
        return sb.toString();
    }

    private static String anonymizeWithDelimiters(List<AnonymizerDictionary> dictionaries,
                                                  String source,
                                                  DelimiterConfig config,
                                                  boolean hashEnabled) {
        if (source == null || source.isEmpty() || dictionaries.isEmpty()) {
            return source;
        }

        List<Token> tokens = splitByDelimiters(source, config);
        boolean changed = false;

        for (Token token : tokens) {
            if (token.delimiter) {
                continue;
            }
            String lookup = token.text.trim();
            if (lookup.isEmpty()) {
                continue;
            }
            String upper = lookup.toUpperCase(Locale.ROOT);
            boolean replaced = false;
            for (AnonymizerDictionary dict : dictionaries) {
                if (dict == null || dict.pairMap.isEmpty()) {
                    continue;
                }
                String replacement = dict.pairMap.get(upper);
                if (replacement != null) {
                    token.text = applyCaseFormat(replacement, token.text);
                    changed = true;
                    replaced = true;
                    break;
                }
            }
            if (!replaced && hashEnabled) {
                String hashed = hashValue(token.text);
                if (!token.text.equals(hashed)) {
                    token.text = hashed;
                    changed = true;
                }
            }
        }

        if (!changed) {
            return source;
        }
        return joinTokens(tokens);
    }

    private static class TableRef {
        final String owner;
        final String name;

        TableRef(String owner, String name) {
            this.owner = owner;
            this.name = name;
        }

        String toSqlName() {
            if (owner == null || owner.isEmpty()) {
                return quoteIdentifier(name);
            }
            return quoteIdentifier(owner) + "." + quoteIdentifier(name);
        }
    }

    public static String pflb_load_dictionary(int dictId, String dictName, String tableName) {
        // Читаем значения из таблицы, приводим к верхнему регистру, сохраняем в памяти
        try {
            if (dictName == null || dictName.trim().isEmpty() || tableName == null || tableName.trim().isEmpty()) {
                return "ERROR: Все параметры обязательны";
            }

            TableRef table = resolveTableReference(tableName);
            Connection conn = getDefaultConnection();
            String dataColumn = getFirstDataColumn(conn, table);
            if (dataColumn == null) {
                return "ERROR: Не найден подходящий столбец";
            }

            AnonymizerDictionary dict = new AnonymizerDictionary();
            dict.id = dictId;
            dict.name = dictName;

            String columnSql = quoteIdentifier(dataColumn);
            String sql = "SELECT " + columnSql + " FROM " + table.toSqlName()
                    + " WHERE " + columnSql + " IS NOT NULL AND LENGTH(TRIM(" + columnSql + ")) > 0 ORDER BY " + columnSql;

            try (Statement stmt = conn.createStatement();
                 ResultSet rs = stmt.executeQuery(sql)) {
                while (rs.next()) {
                    String value = rs.getString(1);
                    if (value != null) {
                        String trimmed = value.trim();
                        if (!trimmed.isEmpty()) {
                            dict.originalValues.add(trimmed.toUpperCase(Locale.ROOT));
                        }
                    }
                }
            }

            if (dict.originalValues.isEmpty()) {
                return "ERROR: Таблица пуста или столбец без данных";
            }

            dict.anonymizedValues = new ArrayList<>(dict.originalValues);
            dict.loadTimestamp = System.currentTimeMillis();

            Map<Integer, AnonymizerDictionary> store = getSessionStore();
            store.put(dictId, dict);

            return "SUCCESS: Словарь '" + dictName + "' загружен. Записей: " + dict.originalValues.size();
        } catch (Exception ex) {
            return "ERROR: " + ex.getMessage();
        }
    }

    private static String getFirstDataColumn(Connection conn, TableRef table) throws SQLException {
        // Ищем первый не-ID столбец, в котором присутствуют непустые значения
        String sql = "SELECT column_name FROM all_tab_columns WHERE owner = ? AND table_name = ? ORDER BY column_id";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, table.owner);
            ps.setString(2, table.name);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String column = rs.getString(1);
                    if (column == null) {
                        continue;
                    }
                    if ("ID".equalsIgnoreCase(column)) {
                        continue;
                    }
                    String columnSql = quoteIdentifier(column);
                    String probeSql = "SELECT " + columnSql + " FROM " + table.toSqlName()
                            + " WHERE " + columnSql + " IS NOT NULL AND ROWNUM = 1";
                    try (Statement probe = conn.createStatement();
                         ResultSet probeRs = probe.executeQuery(probeSql)) {
                        if (probeRs.next() && probeRs.getString(1) != null) {
                            return column;
                        }
                    }
                }
            }
        }
        return null;
    }

    public static String pflb_load_dictionary_from_string(int dictId, String dictName, String dataValues) {
        // Загружаем словарь из строки с разделителями
        try {
            if (dictName == null || dictName.trim().isEmpty() || dataValues == null || dataValues.trim().isEmpty()) {
                return "ERROR: Все параметры обязательны";
            }

            AnonymizerDictionary dict = new AnonymizerDictionary();
            dict.id = dictId;
            dict.name = dictName;

            StringTokenizer tokenizer = new StringTokenizer(dataValues, "|;\n\r");
            while (tokenizer.hasMoreTokens()) {
                String token = tokenizer.nextToken().trim();
                if (!token.isEmpty()) {
                    dict.originalValues.add(token.toUpperCase(Locale.ROOT));
                }
            }

            if (dict.originalValues.isEmpty()) {
                return "ERROR: Не удалось извлечь значения из строки";
            }

            dict.anonymizedValues = new ArrayList<>(dict.originalValues);
            dict.loadTimestamp = System.currentTimeMillis();

            Map<Integer, AnonymizerDictionary> store = getSessionStore();
            store.put(dictId, dict);

            return "SUCCESS: Словарь '" + dictName + "' загружен. Записей: " + dict.originalValues.size();
        } catch (Exception ex) {
            return "ERROR: " + ex.getMessage();
        }
    }

    public static String pflb_load_dictionary_from_clob(int dictId, String dictName, Clob dataValues) {
        // Поддержка загрузки из CLOB (например, из таблицы с большими текстами)
        try {
            if (dataValues == null) {
                return "ERROR: Все параметры обязательны";
            }
            long length = dataValues.length();
            if (length == 0) {
                return "ERROR: Не удалось извлечь значения из строки";
            }
            String content = dataValues.getSubString(1, (int) Math.min(length, Integer.MAX_VALUE));
            return pflb_load_dictionary_from_string(dictId, dictName, content);
        } catch (Exception ex) {
            return "ERROR: " + ex.getMessage();
        }
    }

    public static String pflb_generate_dictionary_pairs(int dictId, String shuffleKey) {
        // Создаём карту "оригинал -> анонимизированное" после детерминированного перемешивания
        try {
            Map<Integer, AnonymizerDictionary> store = getSessionStore();
            AnonymizerDictionary dict = store.get(dictId);
            if (dict == null) {
                return "ERROR: Словарь с ID " + dictId + " не найден";
            }

            if (dict.originalValues.isEmpty()) {
                return "ERROR: Словарь с ID " + dictId + " пуст";
            }

            dict.anonymizedValues = new ArrayList<>(dict.originalValues);
            deterministicShuffle(dict.anonymizedValues, shuffleKey == null ? "" : shuffleKey);

            dict.pairMap.clear();
            for (int i = 0; i < dict.originalValues.size(); i++) {
                dict.pairMap.put(dict.originalValues.get(i), dict.anonymizedValues.get(i));
            }

            return "SUCCESS: Сгенерировано " + dict.originalValues.size() + " пар для ID=" + dictId;
        } catch (Exception ex) {
            return "ERROR: " + ex.getMessage();
        }
    }

    public static String pflb_anonymize_value(int dictId,
                                              String delimitersTable,
                                              String hashMode,
                                              String maxLengthMode,
                                              String valueToAnonymize) {
        // Возвращаем замену, сохраняя исходный регистр текста
        int maxLength = parseMaxLength(maxLengthMode);
        try {
            if (valueToAnonymize == null || valueToAnonymize.isEmpty()) {
                return applyMaxLength("", maxLength);
            }

            Map<Integer, AnonymizerDictionary> store = getSessionStore();
            AnonymizerDictionary dict = store.get(dictId);
            if (dict == null) {
                return applyMaxLength(valueToAnonymize, maxLength);
            }

            if (dict.pairMap.isEmpty()) {
                return applyMaxLength(valueToAnonymize, maxLength);
            }

            boolean hashEnabled = isHashEnabled(hashMode);
            DelimiterConfig config = loadDelimiters(delimitersTable);
            if (!config.enabled) {
                String upper = valueToAnonymize.toUpperCase(Locale.ROOT);
                String replacement = dict.pairMap.get(upper);
                if (replacement == null) {
                    if (hashEnabled) {
                        return applyMaxLength(hashValue(valueToAnonymize), maxLength);
                    }
                    return applyMaxLength(valueToAnonymize, maxLength);
                }
                return applyMaxLength(applyCaseFormat(replacement, valueToAnonymize), maxLength);
            }

            String result = anonymizeWithDelimiters(Collections.singletonList(dict), valueToAnonymize, config, hashEnabled);
            return applyMaxLength(result, maxLength);
        } catch (Exception ex) {
            return applyMaxLength("ERROR: " + ex.getMessage(), maxLength);
        }
    }

    public static String pflb_anonymize_value_multi(String dictIds,
                                                    String delimitersTable,
                                                    String hashMode,
                                                    String maxLengthMode,
                                                    String valueToAnonymize) {
        // Перебираем словари по списку ID и возвращаем первую найденную замену
        int maxLength = parseMaxLength(maxLengthMode);
        try {
            if (dictIds == null || dictIds.trim().isEmpty() || valueToAnonymize == null || valueToAnonymize.isEmpty()) {
                return applyMaxLength("", maxLength);
            }

            Map<Integer, AnonymizerDictionary> store = getSessionStore();
            String[] parts = dictIds.split(",");
            List<AnonymizerDictionary> dictionaries = new ArrayList<>();
            for (String part : parts) {
                try {
                    int id = Integer.parseInt(part.trim());
                    AnonymizerDictionary dict = store.get(id);
                    if (dict != null && !dict.pairMap.isEmpty()) {
                        dictionaries.add(dict);
                    }
                } catch (NumberFormatException ignored) {
                }
            }

            if (dictionaries.isEmpty()) {
                return applyMaxLength(valueToAnonymize, maxLength);
            }

            boolean hashEnabled = isHashEnabled(hashMode);
            DelimiterConfig config = loadDelimiters(delimitersTable);
            if (!config.enabled) {
                String upper = valueToAnonymize.toUpperCase(Locale.ROOT);
                for (AnonymizerDictionary dict : dictionaries) {
                    String replacement = dict.pairMap.get(upper);
                    if (replacement != null) {
                        return applyMaxLength(applyCaseFormat(replacement, valueToAnonymize), maxLength);
                    }
                }
                if (hashEnabled) {
                    return applyMaxLength(hashValue(valueToAnonymize), maxLength);
                }
                return applyMaxLength(valueToAnonymize, maxLength);
            }

            String result = anonymizeWithDelimiters(dictionaries, valueToAnonymize, config, hashEnabled);
            return applyMaxLength(result, maxLength);
        } catch (Exception ex) {
            return applyMaxLength("ERROR: " + ex.getMessage(), maxLength);
        }
    }

    public static String pflb_list_dictionaries() {
        // Сводная информация по словарям, загруженным в текущей сессии
        try {
            String sessionKey = getCurrentSessionKey();
            Map<Integer, AnonymizerDictionary> store = sessionDictionaries.get(sessionKey);
            if (store == null || store.isEmpty()) {
                return "Словари не загружены (текущая сессия)";
            }

            StringBuilder sb = new StringBuilder();
            sb.append("Загруженные словари для сессии=").append(sessionKey).append(":\n");
            List<Integer> keys = new ArrayList<>(store.keySet());
            Collections.sort(keys);
            for (Integer id : keys) {
                AnonymizerDictionary dict = store.get(id);
                if (dict == null) {
                    continue;
                }
                String timestamp = formatTimestamp(dict.loadTimestamp);
                sb.append("ID: ").append(dict.id)
                        .append(", Название: '").append(dict.name).append("', Записей: ")
                        .append(dict.originalValues.size()).append(", Пар: ")
                        .append(dict.pairMap.size()).append(", Загружен: ")
                        .append(timestamp).append('\n');
            }
            return sb.toString();
        } catch (Exception ex) {
            return "ERROR: " + ex.getMessage();
        }
    }

    public static String pflb_dictionary_stats(int dictId) {
        // Детальная статистика по выбранному словарю
        try {
            Map<Integer, AnonymizerDictionary> store = getSessionStore();
            AnonymizerDictionary dict = store.get(dictId);
            if (dict == null) {
                return "ERROR: Словарь с ID " + dictId + " не найден";
            }
            StringBuilder sb = new StringBuilder();
            sb.append("Статистика словаря ID=").append(dictId).append(":\n");
            sb.append("Название: ").append(dict.name).append('\n');
            sb.append("Исходных записей: ").append(dict.originalValues.size()).append('\n');
            sb.append("Готовых пар: ").append(dict.pairMap.size()).append('\n');
            sb.append("Время загрузки: ").append(formatTimestamp(dict.loadTimestamp)).append('\n');
            return sb.toString();
        } catch (Exception ex) {
            return "ERROR: " + ex.getMessage();
        }
    }

    public static String pflb_reset_dictionary(int dictId) {
        // Удаление словаря из памяти текущей сессии
        try {
            Map<Integer, AnonymizerDictionary> store = getSessionStore();
            if (store.remove(dictId) != null) {
                return "SUCCESS: Словарь с ID " + dictId + " удалён";
            }
            return "WARNING: Словарь с ID " + dictId + " не найден";
        } catch (Exception ex) {
            return "ERROR: " + ex.getMessage();
        }
    }

    public static String pflb_reset_all_dictionaries() {
        // Полная очистка словарей текущей сессии
        try {
            String sessionKey = getCurrentSessionKey();
            if (sessionDictionaries.remove(sessionKey) != null) {
                return "SUCCESS: Все словари текущей сессии удалены";
            }
            return "WARNING: Для текущей сессии словари не найдены";
        } catch (Exception ex) {
            return "ERROR: " + ex.getMessage();
        }
    }

    private static void deterministicShuffle(List<String> list, String key) {
        // Алгоритм Фишера-Йетса с LCG-генератором — детерминированный shuffle
        if (list.size() < 2) {
            return;
        }
        long[] state = new long[]{djb2(key)};
        for (int i = list.size() - 1; i > 0; i--) {
            int j = (int) (next(state) % (i + 1));
            if (j != i) {
                String tmp = list.get(i);
                list.set(i, list.get(j));
                list.set(j, tmp);
            }
        }
    }

    private static long djb2(String s) {
        // Хэш-функция для получения начального состояния LCG
        long hash = 5381L;
        if (s != null) {
            for (int i = 0; i < s.length(); i++) {
                hash = ((hash << 5) + hash) + s.charAt(i);
            }
        }
        return hash & 0xFFFFFFFFL;
    }

    private static long next(long[] state) {
        // Одно шаговое преобразование LCG
        long value = state[0];
        value = (value * 1664525L + 1013904223L) & 0xFFFFFFFFL;
        state[0] = value;
        return value;
    }

    private static String applyCaseFormat(String replacement, String original) {
        // Подгоняем регистр результата под исходное значение (ВСЕ ЗАГЛАВНЫЕ / строчные / Title Case)
        if (replacement == null || replacement.isEmpty() || original == null || original.isEmpty()) {
            return replacement;
        }

        boolean hasUpper = false;
        boolean hasLower = false;
        for (int i = 0; i < original.length(); i++) {
            char c = original.charAt(i);
            if (Character.isUpperCase(c)) {
                hasUpper = true;
            } else if (Character.isLowerCase(c)) {
                hasLower = true;
            }
        }

        if (hasUpper && !hasLower) {
            return replacement.toUpperCase(Locale.ROOT);
        }
        if (!hasUpper && hasLower) {
            return replacement.toLowerCase(Locale.ROOT);
        }
        if (Character.isLetter(original.charAt(0)) && Character.isUpperCase(original.charAt(0))) {
            if (replacement.length() == 1) {
                return replacement.toUpperCase(Locale.ROOT);
            }
            return replacement.substring(0, 1).toUpperCase(Locale.ROOT)
                    + replacement.substring(1).toLowerCase(Locale.ROOT);
        }
        return replacement;
    }

    private static String formatTimestamp(long timestamp) {
        // Преобразуем миллисекунды в читаемую дату для диагностики
        if (timestamp == 0L) {
            return "-";
        }
        return new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.ROOT).format(new Date(timestamp));
    }
}
;
/ --HARDCODE FOR DEPLOYMENT