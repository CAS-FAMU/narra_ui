#
# Copyright (C) 2015 CAS / FAMU
#
# This file is part of narra-ui.
#
# narra-ui is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# narra-ui is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with narra-ui. If not, see <http://www.gnu.org/licenses/>.
#
# Authors: Michal Mocnak <michal@marigan.net>
#

angular.module('narra.ui').factory 'serviceLayouts', ->
  layouts: ->
    [
      {
        id: 'visualization_only',
        name: 'Visualization Only',
        description: 'Layout using only one visualization in the runtime with possibility to activate selector',
        options: {
          visualization: ''
        }
      }
      {
        id: 'sequence_player_only',
        name: 'Sequence Player Only',
        description: 'Layout using only one player in the runtime to play sequences',
        options: {
          sequence: ''
        }
      }
      {
        id: 'sequence_player_with_metadata',
        name: 'Sequence Player With Metadata',
        description: 'Layout using only one player in the runtime to play sequences with possibility to see metadata of items',
        options: {
          sequence: ''
          metadata_fields: 'keywords'
        }
      }
      {
        id: 'sequence_player_with_context',
        name: 'Sequence Player With Context',
        description: 'Layout using only one player in the runtime to play sequences with possibility to see contextual data from synthesizers',
        options: {
          sequence: ''
          contextual_synthesizers: 'sequence'
        }
      }
    ]