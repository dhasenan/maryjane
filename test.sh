#!/bin/bash
NODE_PATH=$(readlink -f lib) coffee test/maryjanetests.coffee
