//
//  Departement
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 23/12/2018.
//  Copyright © 2018 Alexandre GUY. All rights reserved.
//
//  Licence: GPLv3

//
//  La classe Departement
//

package org.giletsjaunes.compteur;


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// classe département
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
public class Departement {

    public final String id;
    public final String nom;
    public final String nombre_total;
    public final String longitude;
    public final String latitude;


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // constructeur
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public Departement(String id, String nom, String nombre_total, String longitude, String latitude) {
        this.id = id;
        this.nom = nom;
        this.nombre_total = nombre_total;
        this.longitude = longitude;
        this.latitude = latitude;
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // getId
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public String getId() {
        return this.id;
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // toString
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public String toString() {
        return "\nid:" + this.id + "\nnom:" + this.nom + "\nnombre_total:" + this.nombre_total
                + "\nlongitude:" + this.longitude + "\nlatitude:" + this.latitude + "\n";
    }

}
