#!/bin/bash

function user_is_root() {
    [ $(id -u) -eq 0 ]
}
