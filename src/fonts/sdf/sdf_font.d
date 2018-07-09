module fonts.sdf.sdf_font;
/**
 *  Signed distance field font.
 */
import fonts.all;
import std.stdio : File, writefln;
import std.algorithm : startsWith;
import std.string : strip;
import std.array : split;
import std.conv : to;

final class SDFFont {
private:
    string directory;
    string name;
    FontPage page;
    ubyte[] data;
public:
    uint size, width, height, lineHeight;

    ubyte[] getData() { return data; }
    FontChar getChar(uint i) { return page[i]; }
    FontChar getChar(string s) { return page[s[0]]; }
    int getKerning(uint from, uint to) {
        return page.kernings.get((cast(ulong)from)<<32 | to, 0);
    }

    this(string directory, string name) {
        this.directory = directory;
        this.name      = name;
        readPage();
        readData();
    }
    Rect getRect(string text, float size) {
        auto r = Rect(0,0,0,0);
        if(text.length==0) return r;
        r.x = 1000;
        r.y = 1000;
        float X = 0;
        foreach(i, ch; text) {
            FontChar g = page[ch];

            float ratio = (size/cast(float)this.size);

            float x  = X + g.xoffset * ratio;
            float y  = 0 + g.yoffset * ratio;
            float xx = x + g.width * ratio;
            float yy = y + g.height * ratio;

            if(x<r.x) r.x = x;
            if(y<r.y) r.y = y;
            if(xx > r.width) r.width = xx;
            if(yy > r.height) r.height = yy;

            int kerning = 0;
            if(i<text.length-1) {
                kerning = getKerning(ch, text[i+1]);
            }
            X += (g.xadvance + kerning) * ratio;
        }
        return r;
    }
    Dimension getDimension(string text, float size) {
        return getRect(text, size).dimension;
    }
    override string toString() {
        return "[SDFFont %s]".format(name);
    }
private:
    void readPage() {
        page = new FontPage();
        scope f = File(directory~name~".fnt", "r");
        string line;

        string getFirstToken(long offset=0) {
            auto p=offset;
            while(p<line.length && line[p]>32) p++;
            return line[offset..p];
        }
        int getInt(string key) {
            auto p = line.indexOf(key);
            string token = getFirstToken(p+key.length);
            return token.to!int;
        }

        while((line = f.readln()) !is null) {
            line = line.strip();
            if(line.length==0) continue;
            const firstToken = getFirstToken();
            //log("firstToken=%s", firstToken); flushLog();

            switch(firstToken) {
                case "info" :
                    size = getInt("size=");
                    break;
                case "common":
                    width      = getInt("scaleW=");
                    height     = getInt("scaleH=");
                    lineHeight = getInt("lineHeight=");
                    break;
                case "char" :
                    auto c = new FontChar(line, width);
                    page.chars[c.id] = c;
                    break;
                case "kerning" :
                    ulong first  = getInt("first=");
                    ulong second = getInt("second=");
                    int amount   = getInt("amount=");
                    page.kernings[(first<<32)|second] = amount;
                    break;
                default : break;
            }
        }
    }
    void readData() {
        data = PNG.read(directory~name~".png").getAlpha().data;
    }
}

// char id=0 x=237  y=102  width=25   height=29   xoffset=-4   yoffset=11   xadvance=24   page=0    chnl=0
final class FontChar {
    uint id;
    float u, v, u2, v2;
    uint width, height;
    int xoffset, yoffset;
    uint xadvance;
    this(string line, float bmwidth) {
        // remove 'char'
        line = line[4..$].strip();
        // assumes there are no spaces around '='
        auto tokens = line.split();
        string[string] map;
        foreach(t; tokens) {
            auto pair = t.split("=");
            map[pair[0]] = pair[1];
        }
        this.id       = map["id"].to!uint;
        float x       = map["x"].to!float;
        float y       = map["y"].to!float;
        this.width    = map["width"].to!uint;
        this.height   = map["height"].to!uint;
        this.xoffset  = map["xoffset"].to!int;
        this.yoffset  = map["yoffset"].to!int;
        this.xadvance = map["xadvance"].to!uint;

        this.u  = x / bmwidth;
        this.v  = y / bmwidth;
        this.u2 = (x+width) / bmwidth;
        this.v2 = (y+height) / bmwidth;
    }
}
private final class FontPage {
    FontChar[uint] chars;
    int[ulong] kernings;    // key = (from<<32 | to)

    bool hasChar(uint c) {
        return (c in chars) !is null;
    }
    FontChar opIndex(int i) {
        return hasChar(i) ? chars[i] : chars[cast(int)' '];
    }
}

