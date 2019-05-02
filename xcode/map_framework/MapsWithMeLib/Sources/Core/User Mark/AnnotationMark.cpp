//
//  AnnotationMark.cpp
//  MapsWithMeLib
//
//  Created by Dmitry Letko on 4/15/19.
//  Copyright © 2019 WiFi Map. All rights reserved.
//

#import "AnnotationMark.hpp"

AnnotationMark::AnnotationMark(m2::PointD const &ptOrg): StaticMarkPoint(ptOrg) {
    m_symbol = "";
    m_isHidden = false;
}

drape_ptr<df::UserPointMark::SymbolNameZoomInfo> AnnotationMark::GetSymbolNames() const {
    auto symbol = make_unique_dp<SymbolNameZoomInfo>();
    symbol->insert(std::make_pair(1 /* zoomLevel */, m_symbol));

    return symbol;
}

bool AnnotationMark::IsVisible() const {
    return !m_isHidden;
}

void AnnotationMark::SetHidden(bool isHidden) {
    if (m_isHidden != isHidden) {
        m_isHidden = isHidden;

        SetDirty();
    }
}

void AnnotationMark::SetSymbol(std::string const & symbol) {
    if (m_symbol != symbol) {
        m_symbol = symbol;

        SetDirty();
    }
}
