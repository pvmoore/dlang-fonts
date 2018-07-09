module test_sdffont;
/**
 *
 */
import fonts;
import std.stdio;

void main() {
    writefln("Testing signed distance field fonts");

    auto font = new SDFFont("../../../_assets/fonts/hiero/", "arial-black");

    assert(font.size==32);
    assert(font.width==512);
    assert(font.height==512);

    auto a = font.getChar("A");
    auto a2 = font.getChar('A');

    assert(a.id==65 && a2.id==65);

    assert(a.u==0.4765625 && a.v==0);
    assert(a.u2==0.541015625 && a.v2==0.0625);

    assert(a.width==33 && a.height==32);
    assert(a.xoffset==-4 && a.yoffset==8 && a.xadvance==25);

    assert(font.getData().length==512*512);

    assert(font.getKerning(112,119)==-1);
    assert(font.getKerning(5000,10000)==0);

    // ----

    font = new SDFFont("../../../_assets/fonts/hiero/", "arial-black-ext");

    assert(font.size==32);
    assert(font.width==1024);
    assert(font.height==1024);
    writefln("OK");
}


