#!/bin/env perl

use lib 't';
use Test::Class;
use Test::Lystyng::Schema;
use Test::Lystyng::Schema::Result::User;
use Test::Lystyng::Schema::Result::List;
use Test::Lystyng::Schema::Result::ListItem;

Test::Class->runtests;
