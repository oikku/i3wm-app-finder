#!/usr/bin/env swipl

:- initialization go.
:- use_module(library(http/json)).

get_windows(Output) :-
    process_create(
        path('i3-msg'), ['-t', 'get_tree'],
        [stdout(pipe(Out))]),
    json_read_dict(Out, Output),
    close(Out).

ignore_window(Window) :- get_dict(focused, Window, false).

find_focused_rect(H, Out) :-
    is_dict(H),
    _{focused: true, rect:Out} :< H.
find_focused_rect(H, Out) :-
    is_dict(H),
    _{nodes: Nodes} :< H,
    find_focused_rect(Nodes, Out).
find_focused_rect(H, _) :- is_dict(H), fail.
find_focused_rect([H|T], Out) :-
    find_focused_rect(H, Out);
    find_focused_rect(T, Out).
find_focused_rect([H], Out) :-
    find_focused_rect(H, Out).

take_screenshot(_, rectangle) :-
    create_filename(Filename),
    process_create(path('import'), [Filename], []).
take_screenshot(R, window) :-
    _{height:H, width:W, x:X, y:Y} :< R,
    atomics_to_string([W, x, H, '+', X, '+', Y], Geometry),
    create_filename(Filename),
    process_create(path('import'), ['-window', root, '-crop', Geometry, Filename], []).

create_filename(Filename) :-
    get_time(Time),
    format_time(atom(FormattedTime), '%Y-%m-%dT%H%m%S', Time),
    getenv('HOME', HomeDir),
    atomics_to_string([
            HomeDir, '/screenshots/screenshot-', 
            FormattedTime, 
            '.png'], Filename).
    

go :-
    catch(
        run_selection, 
        E, 
        (print_message(error, E), fail)
    ),
    halt(0).
go :- halt(1).

run_selection :-
    (current_prolog_flag(argv, [Type]); Type = rectangle),
    get_windows(W),
    find_focused_rect(W, R),
    take_screenshot(R, Type).
