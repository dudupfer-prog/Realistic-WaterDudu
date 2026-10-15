uint typeAt(ivec3 c) {
    return inBox(c) ? (cellFlags[cellIndex(c)] & 0xFFu) : CELL_AIR;
}

float faceVel(int comp, ivec3 f) {
    return faceInBox(comp, f) ? vel[faceIndex(comp, f)] : 0.0;
}

ivec2 planeAxes(int plane) {
    return plane == 0 ? ivec2(0, 1) : (plane == 1 ? ivec2(0, 2) : ivec2(1, 2));
}

float edgeStrain0(ivec3 e) {
    float dadb = faceVel(0, e) - faceVel(0, e - ivec3(0, 1, 0));
    float dbda = faceVel(1, e) - faceVel(1, e - ivec3(1, 0, 0));
    return 0.5 * (dadb + dbda);
}

float edgeStrain1(ivec3 e) {
    float dadb = faceVel(0, e) - faceVel(0, e - ivec3(0, 0, 1));
    float dbda = faceVel(2, e) - faceVel(2, e - ivec3(1, 0, 0));
    return 0.5 * (dadb + dbda);
}

float edgeStrain2(ivec3 e) {
    float dadb = faceVel(1, e) - faceVel(1, e - ivec3(0, 0, 1));
    float dbda = faceVel(2, e) - faceVel(2, e - ivec3(0, 1, 0));
    return 0.5 * (dadb + dbda);
}

float edgeStrain(int plane, ivec3 e) {
    if (plane == 0) return edgeStrain0(e);
    if (plane == 1) return edgeStrain1(e);
    return edgeStrain2(e);
}

bool edgeActive0(ivec3 e) {
    uint t0 = typeAt(e);                     if (t0 == CELL_AIR) return false;
    uint t1 = typeAt(e - ivec3(1, 0, 0));    if (t1 == CELL_AIR) return false;
    uint t2 = typeAt(e - ivec3(0, 1, 0));    if (t2 == CELL_AIR) return false;
    uint t3 = typeAt(e - ivec3(1, 1, 0));    if (t3 == CELL_AIR) return false;
    return (t0 == CELL_FLUID || t1 == CELL_FLUID || t2 == CELL_FLUID || t3 == CELL_FLUID);
}

bool edgeActive1(ivec3 e) {
    uint t0 = typeAt(e);                     if (t0 == CELL_AIR) return false;
    uint t1 = typeAt(e - ivec3(1, 0, 0));    if (t1 == CELL_AIR) return false;
    uint t2 = typeAt(e - ivec3(0, 0, 1));    if (t2 == CELL_AIR) return false;
    uint t3 = typeAt(e - ivec3(1, 0, 1));    if (t3 == CELL_AIR) return false;
    return (t0 == CELL_FLUID || t1 == CELL_FLUID || t2 == CELL_FLUID || t3 == CELL_FLUID);
}

bool edgeActive2(ivec3 e) {
    uint t0 = typeAt(e);                     if (t0 == CELL_AIR) return false;
    uint t1 = typeAt(e - ivec3(0, 1, 0));    if (t1 == CELL_AIR) return false;
    uint t2 = typeAt(e - ivec3(0, 0, 1));    if (t2 == CELL_AIR) return false;
    uint t3 = typeAt(e - ivec3(0, 1, 1));    if (t3 == CELL_AIR) return false;
    return (t0 == CELL_FLUID || t1 == CELL_FLUID || t2 == CELL_FLUID || t3 == CELL_FLUID);
}

bool edgeActive(int plane, ivec3 e) {
    if (plane == 0) return edgeActive0(e);
    if (plane == 1) return edgeActive1(e);
    return edgeActive2(e);
}

void cellStrain(ivec3 c, out vec3 diag, out vec3 shear) {
    diag = vec3(
        faceVel(0, c + ivec3(1, 0, 0)) - faceVel(0, c),
        faceVel(1, c + ivec3(0, 1, 0)) - faceVel(1, c),
        faceVel(2, c + ivec3(0, 0, 1)) - faceVel(2, c));
    diag -= (diag.x + diag.y + diag.z) * (1.0 / 3.0);

    // Plane 0 (XY)
    {
        float sum = 0.0;
        float n = 0.0;
        ivec3 e0 = c;
        if (edgeActive0(e0)) { sum += edgeStrain0(e0); n += 1.0; }
        ivec3 e1 = c + ivec3(1, 0, 0);
        if (edgeActive0(e1)) { sum += edgeStrain0(e1); n += 1.0; }
        ivec3 e2 = c + ivec3(0, 1, 0);
        if (edgeActive0(e2)) { sum += edgeStrain0(e2); n += 1.0; }
        ivec3 e3 = c + ivec3(1, 1, 0);
        if (edgeActive0(e3)) { sum += edgeStrain0(e3); n += 1.0; }
        shear.x = n > 0.0 ? sum / n : 0.0;
    }

    // Plane 1 (XZ)
    {
        float sum = 0.0;
        float n = 0.0;
        ivec3 e0 = c;
        if (edgeActive1(e0)) { sum += edgeStrain1(e0); n += 1.0; }
        ivec3 e1 = c + ivec3(1, 0, 0);
        if (edgeActive1(e1)) { sum += edgeStrain1(e1); n += 1.0; }
        ivec3 e2 = c + ivec3(0, 0, 1);
        if (edgeActive1(e2)) { sum += edgeStrain1(e2); n += 1.0; }
        ivec3 e3 = c + ivec3(1, 0, 1);
        if (edgeActive1(e3)) { sum += edgeStrain1(e3); n += 1.0; }
        shear.y = n > 0.0 ? sum / n : 0.0;
    }

    // Plane 2 (YZ)
    {
        float sum = 0.0;
        float n = 0.0;
        ivec3 e0 = c;
        if (edgeActive2(e0)) { sum += edgeStrain2(e0); n += 1.0; }
        ivec3 e1 = c + ivec3(0, 1, 0);
        if (edgeActive2(e1)) { sum += edgeStrain2(e1); n += 1.0; }
        ivec3 e2 = c + ivec3(0, 0, 1);
        if (edgeActive2(e2)) { sum += edgeStrain2(e2); n += 1.0; }
        ivec3 e3 = c + ivec3(0, 1, 1);
        if (edgeActive2(e3)) { sum += edgeStrain2(e3); n += 1.0; }
        shear.z = n > 0.0 ? sum / n : 0.0;
    }
}
