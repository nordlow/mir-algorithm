/++
A simple I/O routines around `<stdio.h>`.

The implementation is CTFE-friendly.
+/
module mir.stdio;

static import core.stdc.stdio;

/// Standart output
File dout()() @trusted nothrow @nogc @property
{
    version(LDC)
        pragma(inline, true);
    return File(__ctfe ? null : core.stdc.stdio.stdout);
}

/// ditto
File derr()() @trusted nothrow @nogc @property
{
    version(LDC)
        pragma(inline, true);
    return File(__ctfe ? null : core.stdc.stdio.stderr);
}

///
version(mir_test)
@safe @nogc
unittest
{
    dout << "mir.stdio.dout test! - @nogc I/O" << endl;
    derr << "mir.stdio.derr test! - @nogc I/O" << endl;
}

/++
Nothrow standart output to use in pair with `debug` expression in nothrow
and pure code for testing purpose.

See_also: $(LREF AssumeNothrowFile)
+/
AssumeNothrowFile tout()() @trusted nothrow @nogc @property
{
    version(LDC)
        pragma(inline, true);
    return AssumeNothrowFile(__ctfe ? null : core.stdc.stdio.stdout);
}

/// ditto
AssumeNothrowFile terr()() @trusted nothrow @nogc @property
{
    version(LDC)
        pragma(inline, true);
    return AssumeNothrowFile(__ctfe ? null : core.stdc.stdio.stderr);
}

///
version(mir_test)
pure @safe @nogc nothrow
unittest
{
    debug tout << "mir.stdio.tout test! - @nogc nothrow I/O" << endl;
    debug terr << "mir.stdio.terr test! - @nogc nothrow I/O" << endl;
}

/++
When used as `file << endl` it adds new line flushes the stream.
+/
enum NewLine
{
    lf = "\n",
    lf_cf = "\r\n",
}

/// ditto
enum endl = NewLine.lf;

/++
+/
struct File
{
    ///
    core.stdc.stdio.FILE* fp;

    mixin FileMemembers;

@trusted @nogc:

    /++
    Throws: $(LREF FileException)
    +/
    void rawWrite(scope const(void)[] data)
        in (__ctfe || fp !is null)
    {
        if (__ctfe)
            return;
        core.stdc.stdio.fwrite(data.ptr, 1, data.length, fp);
        if (core.stdc.stdio.ferror(fp))
            throw writeException;
    }

    /++
    Throws: $(LREF FileException)
    +/
    void flush()
        in (__ctfe || fp !is null)
    {
        if (__ctfe)
            return;
        core.stdc.stdio.fflush(fp);
        if (core.stdc.stdio.ferror(fp))
            throw writeException;
    }
}

/++
Nothrow File implementation for testing purposes.
See_also: $(LREF tout), $(LREF terr)
+/
struct AssumeNothrowFile
{
    ///
    core.stdc.stdio.FILE* fp;

    mixin FileMemembers;

@trusted @nogc nothrow:

    /++
    Throws: $(LREF FileError)
    +/
    void rawWrite(scope const(void)[] data)
        in (__ctfe || fp !is null)
    {
        if (__ctfe)
            return;
        core.stdc.stdio.fwrite(data.ptr, 1, data.length, fp);
        if (core.stdc.stdio.ferror(fp))
            throw writeError;
    }

    /++
    Throws: $(LREF FileError)
    +/
    void flush()
        in (__ctfe || fp !is null)
    {
        if (__ctfe)
            return;
        core.stdc.stdio.fflush(fp);
        if (core.stdc.stdio.ferror(fp))
            throw writeError;
    }
}

///
mixin template FileMemembers()
{
    ///
    void put(C)(const C data)
        if (is(C == char) || is(C == wchar) | is(C == dchar))
    {
        C[1] array = [data];
        this.rawWrite(array);
    }

    ///
    void put(C)(scope const(C)[] data)
        if (is(C == char) || is(C == wchar) | is(C == dchar))
    {
        this.rawWrite(data);
    }

    ///
    template opBinary(string op : "<<")
    {
        ///
        ref opBinary(T)(auto ref T value) return scope
        {
            import mir.format: print;
            return print!char(this, value);
        }

        /// Prints new line and flushes the stream
        ref opBinary(NewLine endl) return scope
        {
            import mir.format: print;
            this.put(endl);
            this.flush;
            return this;
        }
    }
}

/++
File Exception
+/
class FileException : Exception
{
    ///
    this(
        string msg,
        string file = __FILE__,
        size_t line = __LINE__,
        Throwable next = null) pure nothrow @nogc @safe 
    {
        super(msg, file, line, next);
    }

    ///
    this(
        string msg,
        Throwable next,
        string file = __FILE__,
        size_t line = __LINE__,
        ) pure nothrow @nogc @safe 
    {
        this(msg, file, line, next);
    }

    FileException toMutable() @trusted pure nothrow @nogc const
    {
        return cast() this;
    }

    alias toMutable this;
}

/++
File Error
+/
class FileError : Error
{
    ///
    this(
        string msg,
        string file = __FILE__,
        size_t line = __LINE__,
        Throwable next = null) pure nothrow @nogc @safe 
    {
        super(msg, file, line, next);
    }

    ///
    this(
        string msg,
        Throwable next,
        string file = __FILE__,
        size_t line = __LINE__,
        ) pure nothrow @nogc @safe 
    {
        this(msg, file, line, next);
    }

    FileError toMutable() @trusted pure nothrow @nogc const
    {
        return cast() this;
    }

    alias toMutable this;
}

private static immutable writeException = new FileException("Error on file write");
private static immutable flushException = new FileException("Error on file flush");
private static immutable writeError = new FileError("Error on file write");
private static immutable flushError = new FileError("Error on file flush");
