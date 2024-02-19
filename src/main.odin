package main

import "core:fmt"
import "core:os"

/* There are 5 possible operations */
OpKind :: enum {
    ADD,     // + - 
    MOVE,    // > <
    LOOP,    // [ ]
    INPUT,   // , 
    OUTPUT   // .
}

/* An operation has a kind and an optional operand */
Op :: struct {
    kind : OpKind,
    operand : union {
        i32,
        []Op
    }
}

parse_program :: proc(program_src : []byte) -> []Op {
    using OpKind
    program : [dynamic]Op = {Op{ADD, 0}}
    for i := 0; i < len(program_src); i += 1 {

        c := program_src[i];
        last : ^Op = &program[len(program) - 1]

        switch c {
            case '+': fallthrough
            case '-':
                operand : i32 = (c == '+') ? 1 : -1
                if last.kind == ADD {
                    last.operand = last.operand.(i32) + operand;
                } else {
                    append(&program, Op{ADD, operand})
                }
            case '>': fallthrough
            case '<':
                operand : i32 = (c == '>') ? 1 : -1
                if last.kind == MOVE {
                    last.operand = last.operand.(i32) + operand;
                } else {
                    append(&program, Op{MOVE, operand})
                }
            case '[':
                operand : []Op = parse_program(program_src[i + 1:])
                append(&program, Op{LOOP, operand})
                open_bracket_count := 1
                j := i + 1
                for ; j < len(program_src); j += 1 {
                    if program_src[j] == '[' { open_bracket_count += 1 } 
                    if program_src[j] == ']' { open_bracket_count -= 1 } 
                    if open_bracket_count == 0 { break } 
                }
                i = j
            case ']':
                return program[:]
            case ',': 
                append(&program, Op{INPUT, 0})
            case '.': 
                append(&program, Op{OUTPUT, 0})
            case: continue
        }
    }
    return program[:]
}

ProgramState :: struct {
    ptr  : i32,
    tape : [0x10000]byte
}

interpret_program :: proc(program : []Op, state : ^ProgramState) {
    using OpKind
    for op in program {
        switch op.kind {
            case ADD: state.tape[state.ptr] += cast(u8)(op.operand.(i32) & 0xFF)
            case MOVE: state.ptr += op.operand.(i32)
            case LOOP: 
                for state.tape[state.ptr] != 0 { 
                    interpret_program(op.operand.([]Op), state)
                }
            case INPUT: continue /* TODO */
            case OUTPUT: fmt.print(cast(rune)state.tape[state.ptr])
        } 
    }
}

main :: proc() {
    /* parse args */
    args := os.args[1:]
    if len(args) != 1 {
        fmt.println("Usage: bfodin <brainfuck source file>")
        os.exit(1)
    }
    filepath := args[0]

    /* read file */
    program_src, ok := os.read_entire_file(filepath)
    if !ok {
        fmt.println("could not read file: ", filepath)
        os.exit(1)
    }
    defer delete(program_src)

    /* parse program into IR */
    program := parse_program(program_src[:])

    //for op in program {
    //    fmt.println(op)
    //} 

    /* interpret program */
    state : ProgramState
    interpret_program(program, &state)

}
