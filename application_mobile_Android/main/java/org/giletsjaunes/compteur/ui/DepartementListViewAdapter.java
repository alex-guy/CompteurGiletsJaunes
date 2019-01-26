//
//  DepartementListViewAdapter
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 23/12/2018.
//  Copyright © 2018 Alexandre GUY. All rights reserved.
//
//  Licence: GPLv3

//
//  Mise en forme des départements
//

package org.giletsjaunes.compteur.ui;

import android.app.Activity;
import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.TextView;
import org.giletsjaunes.compteur.Departement;
import org.giletsjaunes.compteur.R;

import java.util.List;


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Cellule du TableView des départements
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
public class DepartementListViewAdapter extends ArrayAdapter<Departement> {

    private final Context context;


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // constructeur
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public DepartementListViewAdapter(Context context, int resourceId,
                                 List<Departement> items) {
        super(context, resourceId, items);
        this.context = context;
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // classe ViewHolder
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    private class ViewHolder {
        TextView txtTitle;
        TextView txtCompteur;
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // getView
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public View getView(int position, View convertView, ViewGroup parent) {
        ViewHolder holder = null;
        Departement departement = getItem(position);

        LayoutInflater mInflater = (LayoutInflater) context
                .getSystemService(Activity.LAYOUT_INFLATER_SERVICE);
        if (convertView == null) {
            convertView = mInflater.inflate(R.layout.region_item_layout, null);
            holder = new ViewHolder();
            holder.txtTitle = (TextView) convertView.findViewById(R.id.nom);
            holder.txtCompteur = (TextView) convertView.findViewById(R.id.nombre_total);
            convertView.setTag(holder);
        } else
            holder = (ViewHolder) convertView.getTag();

        // nom
        holder.txtTitle.setText(departement.nom);
        //holder.txtTitle.setTextColor(Color.rgb(44, 93, 205));
        //holder.txtTitle.setTypeface(Typeface.createFromAsset(context.getAssets(), "font/helvetica-neue-medium.ttf"));

        // compteur
        holder.txtCompteur.setText(departement.nombre_total);

        return convertView;
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // getItemId
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public long getItemId(int position) {
        return position;
    }

}