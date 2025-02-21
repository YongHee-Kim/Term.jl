import Term: RenderableText, Spacer, vLine, hLine, cleantext, textlen, chars, Panel
import Term.layout: pad

@testset "Layout - pad" begin
    @test pad("aaa", 20, :left) == "aaa                 "
    @test pad("aaa", 20, :right) == "                 aaa"
    @test pad("aaa", 20, :center) == "        aaa         "
    @test pad("aaa", 10, 20) == "          aaa                    "
    p = Panel(; width=20, height=10)
    padded = pad(p.segments, 10, 10)
    @test padded[1].measure.w == 40
end

@testset "\e[34mlayout - spacer" begin
    sizes = [(22, 1), (44, 123), (21, 1), (4334, 232)]
    for (w, h) in sizes
        spacer = Spacer(w, h)
        @test spacer.measure.w == w
        @test spacer.measure.h == h
    end
end


@testset "\e[34mlayout - vLine " begin
    for h in [1, 22, 55, 11]
        line = vLine(h)
        @test length(line.segments) == h
        @test line.measure.h == h
    end

    lines = [(22, "bold"), (55, "red on_green")]
    for (h, style) in lines
        line = vLine(h; style = style)
        @test length(line.segments) == h
        @test line.measure.h == h
    end
    line = vLine(5; style="red")
    @test line.segments[1].text == "\e[31m│\e[39m"

    for box in (:MINIMAL_DOUBLE_HEAD, :DOUBLE, :ASCII, :DOUBLE_EDGE)
        @test vLine(22; box = box).measure.h == 22
    end

    panel = Panel(; width=20, height=5)
    @test length(vLine(panel).segments) == 5
    @test vLine().measure.h == displaysize(stdout)[1]
end

@testset "\e[34mlayout - hLine " begin
    for w in [1, 342, 433, 11, 22]
        line = hLine(w)
        @test length(line.segments) == 1
        @test textlen(line.segments[1].text) == w
        @test line.measure.w == w
    end

    for box in (:MINIMAL_DOUBLE_HEAD, :DOUBLE, :ASCII, :DOUBLE_EDGE)
        @test hLine(22; box = box).measure.w == 22
        @test hLine(22, "title"; box = box).measure.w == 22
    end

    for style in ("bold", "red on_green", "blue")
        @test textlen(hLine(11; style = style).segments[1].text) == 11
        @test textlen(hLine(11, "ttl"; style = style).segments[1].text) == 11
    end

    panel = Panel(; width=20, height=5)
    @test hLine().measure.w == displaysize(stdout)[2]
    @test textlen(hLine(panel).segments[1].text) == 20
end


@testset "\e[34mlayout - stack strings" begin
    s1 = "."^50
    s2 = ".\n"^5 * "."
    @test s1 / s2 isa String
end


function testlayout(p, w, h)
    _p = string(p)
    widths = textwidth.(cleantext.(split(_p, "\n")))
    @test length(unique(widths)) == 1

    @test p.measure.w == w
    @test textlen(cleantext(p.segments[1].text)) == w
    @test length(chars(cleantext(p.segments[1].text))) == w

    @test p.measure.h == h
    @test length(p.segments) == h
end

@testset "\e[34mlayout - renderable" begin
    r1 = RenderableText("."^100; width = 25)
    r2 = RenderableText("."^100; width = 50)

    r = r1 / r2
    @test r.measure.w == 50
    @test r.measure.h == 6

    h1 = hLine(22)
    h2 = hLine(33)
    @test (h1 / h2).measure.w == 33
    @test (h1 / h2).measure.h == 2

    r1 = RenderableText("."^100; width = 25)
    r2 = RenderableText("."^100; width = 50)

    r = r1 * r2
    @test r.measure.w == 75
    @test r.measure.h == 4

    # stack other renderables
    h1 = vLine(22)
    h2 = vLine(33)
    @test (h1 * h2).measure.w == 2
    @test (h1 * h2).measure.h == 33


end


@testset "\e[34mlayout - panels" begin
    p1 = Panel()
    p2 = Panel(; width=24, height=3)
    p3 = Panel("this [red]panel[/red]"^5, width=12)
    
    testlayout(p1 * p2, 112, 3)
    @test string(p1 * p2) == "\e[22m╭──────────────────────────────────────────────────────────────────────────────────────╮\e[22m\e[22m╭──────────────────────╮\e[22m\n\e[22m╰──────────────────────────────────────────────────────────────────────────────────────╯\e[22m\e[22m│\e[22m                      \e[0m\e[22m│\e[22m\e[0m\n                                                                                        \e[22m╰──────────────────────╯\e[22m"


    testlayout(p1 / p2, 88, 5)
    @test string(p1 / p2) == "\e[22m╭──────────────────────────────────────────────────────────────────────────────────────╮\e[22m\n\e[22m╰──────────────────────────────────────────────────────────────────────────────────────╯\e[22m\n\e[22m╭──────────────────────╮\e[22m                                                                \n\e[22m│\e[22m                      \e[0m\e[22m│\e[22m\e[0m                                                                \n\e[22m╰──────────────────────╯\e[22m                                                                "

    testlayout(p2 * p1, 112, 3)
    testlayout(p2 / p1, 88, 5)

    testlayout(p1 * p2 * p3, 124, 11)
    testlayout(p1 / p2 / p3, 88, 16)
    testlayout(p3 * p1 * p2, 124, 11)
    testlayout(p3 / p1 / p2, 88, 16)     
end