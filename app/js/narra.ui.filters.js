'use strict';

/*
 #
 # Copyright (C) 2013 CAS / FAMU
 #
 # This file is part of Narra UI.
 #
 # Narra UI is free software: you can redistribute it and/or modify
 # it under the terms of the GNU General Public License as published by
 # the Free Software Foundation, either version 3 of the License, or
 # (at your option) any later version.
 #
 # Narra UI is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 # GNU General Public License for more details.
 #
 # You should have received a copy of the GNU General Public License
 # along with Narra UI. If not, see <http://www.gnu.org/licenses/>.
 #
 # Authors: Michal Mocnak <michal@marigan.net>, Krystof Pesek <krystof.pesek@gmail.com>
 #
 */

// filters
angular.module('narra.ui.filters', []).
    filter('filter_Projectname',function () {
        return function (text) {
            // check whether the text is defined
            (_.isUndefined(text) ? text = "" : text);
            // return properly formated project name
            return angular.lowercase(String(text).replace(/\W+/g, "_").replace(/_{2,}/g, "_").replace(/(^_+|_+$)/g, ""));
        }
    });
