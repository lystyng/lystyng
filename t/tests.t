#!/bin/env perl

use lib 't';
use Test::Class;
use Test::Lystyng::Schema;
use Test::Lystyng::Schema::Result::User;

Test::Class->runtests;
