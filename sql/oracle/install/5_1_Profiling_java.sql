Create or replace and compile java source named Checker as
public class Checker {
    public static String getDigits(String s){
        String res = "";
        for(int i = 0; i < s.length(); i++){
            if(Character.isDigit(s.charAt(i)))
                res += s.charAt(i);
        }
        return res;
    }
    public static boolean CheckINN(String s){
        if (s == null) {
            return false;
        }
        String str=null;
        s = getDigits(s);
        int length = s.length();
        if (s.length() < 10 || s.length() == 11 || s.length() > 12) {
            return false;
        }
        char[] resChar = new char[length];
        int[] ia = new int[length];
        for (int i = 0; i < length; i++) {
            ia[i] = s.charAt(i) - '0';
        }
        int offsetValue;
        if (s.length() == 10) {
            //legal
            for (int i = 0; i < 10; i++) {
                ia[i] = s.charAt(i) - '0';
            }
            resChar[9] = Integer.toString(((2*ia[0] + 4*ia[1] + 10*ia[2] + 3*ia[3] + 5*ia[4] + 9*ia[5] + 4*ia[6] + 6*ia[7] + 8*ia[8]) % 11) % 10).charAt(0);
            return resChar[9] == s.charAt(9);
        } else if (s.length() == 12) {
            ia[10] = (((7*ia[0] +  2*ia[1] +  4*ia[2] +  10*ia[3] +  3*ia[4] +  5*ia[5] +  9*ia[6] +  4*ia[7] +  6*ia[8] +  8*ia[9]) % 11) % 10);
            resChar[10] = Integer.toString(ia[10]).charAt(0);
            resChar[11] = Integer.toString(((3*ia[0] +  7*ia[1] +  2*ia[2] +  4*ia[3] +  10*ia[4] +  3*ia[5] +  5*ia[6] +  9*ia[7] +  4*ia[8] +  6*ia[9] +  8*ia[10]) % 11) % 10).charAt(0);
            return resChar[10] == s.charAt(10) && resChar[11] == s.charAt(11);
        }
        return false;
    }
    public static boolean CheckSnils(String s){
        if (s == null) {
            return false;
        }
        s = getDigits(s);
        String str=null;
        int knum = 0;
        int length = s.length();
        if (s.length() != 11) {
            return false;
        }
        char[] resChar = new char[length];
        int[] ia = new int[length];

        int offsetValue;
        for (int i = 0; i < 10; i++) {
            ia[i] = s.charAt(i) - '0';
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
        return resChar[9] == s.charAt(9) && resChar[10] == s.charAt(10);
    }
    public static boolean CheckOgrn(String s){
        if (s == null) {
            return false;
        }
        s = getDigits(s);
        int length = s.length();

        char[] resChar = new char[length];
        int[] ia = new int[length];

        for (int i = 0; i < length; i++) {
            ia[i] = s.charAt(i) - '0';
        }

        long ogrn = 0;
        int offsetValue;
        if (s.length() == 13) {
            for (int i = 0; i < 12; i++) {
                ogrn = 10*ogrn + ia[i];
            }
            resChar[12] = Long.toString((ogrn % 11) % 10).charAt(0);
            return resChar[12] == s.charAt(12);
        }
        else if (s.length() == 15) {
            for (int i = 0; i < 14; i++) {
                ogrn = 10 * ogrn + ia[i];
            }
            resChar[14] = Long.toString((ogrn % 13) % 10).charAt(0);
            return resChar[14] == s.charAt(14);
        }
        return false;
    }
}
;
/
