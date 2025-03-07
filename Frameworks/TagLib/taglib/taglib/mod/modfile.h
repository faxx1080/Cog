/***************************************************************************
    copyright           : (C) 2011 by Mathias Panzenböck
    email               : grosser.meister.morti@gmx.net
 ***************************************************************************/

/***************************************************************************
 *   This library is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU Lesser General Public License version   *
 *   2.1 as published by the Free Software Foundation.                     *
 *                                                                         *
 *   This library is distributed in the hope that it will be useful, but   *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   Lesser General Public License for more details.                       *
 *                                                                         *
 *   You should have received a copy of the GNU Lesser General Public      *
 *   License along with this library; if not, write to the Free Software   *
 *   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA         *
 *   02110-1301  USA                                                       *
 *                                                                         *
 *   Alternatively, this file is available under the Mozilla Public        *
 *   License Version 1.1.  You may obtain a copy of the License at         *
 *   http://www.mozilla.org/MPL/                                           *
 ***************************************************************************/

#ifndef TAGLIB_MODFILE_H
#define TAGLIB_MODFILE_H

#include <taglib/toolkit/tfile.h>
#include <taglib/audioproperties.h>
#include <taglib/taglib_export.h>
#include <taglib/mod/modfilebase.h>
#include <taglib/mod/modtag.h>
#include <taglib/mod/modproperties.h>

namespace TagLib {

  namespace Mod {

    class TAGLIB_EXPORT File : public TagLib::Mod::FileBase
    {
    public:
      /*!
       * Constructs a Protracker file from \a file.
       *
       * \note In the current implementation, both \a readProperties and
       * \a propertiesStyle are ignored.  The audio properties are always
       * read.
       */
      File(FileName file, bool readProperties = true,
           AudioProperties::ReadStyle propertiesStyle =
           AudioProperties::Average);

      /*!
       * Constructs a Protracker file from \a stream.
       *
       * \note In the current implementation, both \a readProperties and
       * \a propertiesStyle are ignored.  The audio properties are always
       * read.
       *
       * \note TagLib will *not* take ownership of the stream, the caller is
       * responsible for deleting it after the File object.
       */
      File(IOStream *stream, bool readProperties = true,
           AudioProperties::ReadStyle propertiesStyle =
           AudioProperties::Average);

      /*!
       * Destroys this instance of the File.
       */
      virtual ~File();

      Mod::Tag *tag() const;

      /*!
       * Implements the unified property interface -- export function.
       * Forwards to Mod::Tag::properties().
       */
      PropertyMap properties() const;

      /*!
       * Implements the unified property interface -- import function.
       * Forwards to Mod::Tag::setProperties().
       */
      PropertyMap setProperties(const PropertyMap &);
      /*!
       * Returns the Mod::Properties for this file. If no audio properties
       * were read then this will return a null pointer.
       */
      Mod::Properties *audioProperties() const;

      /*!
       * Save the file.
       * This is the same as calling save(AllTags);
       *
       * \note Saving Protracker tags is not supported.
       */
      bool save();

    private:
      File(const File &);
      File &operator=(const File &);

      void read(bool readProperties);

      class FilePrivate;
      FilePrivate *d;
    };

  }

}

#endif
