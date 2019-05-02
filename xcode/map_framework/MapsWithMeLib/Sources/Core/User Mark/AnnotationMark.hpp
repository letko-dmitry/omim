//
//  AnnotationMark.hpp
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/15/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#ifndef AnnotationUserMark_h
#define AnnotationUserMark_h

#import "map/user_mark.hpp"

class AnnotationMark final : public UserMark {
public:
    explicit AnnotationMark(m2::PointD const &ptOrg);

    drape_ptr<SymbolNameZoomInfo> GetSymbolNames() const override;
    df::ColorConstant GetColorConstant() const override;

    void SetSelected(bool isSelected);

private:
    bool m_isSelected;
};

#endif /* AnnotationUserMark_h */
