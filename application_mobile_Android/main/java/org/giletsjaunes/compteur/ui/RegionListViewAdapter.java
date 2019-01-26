//
//  RegionListViewAdapter
//  CompteurGiletsJaunes
//
//  Created by Alexandre GUY on 23/12/2018.
//  Copyright © 2018 Alexandre GUY. All rights reserved.
//
//  Licence: GPLv3

//
//  Mise en forme des régions
//

package org.giletsjaunes.compteur.ui;

import android.app.Activity;
import android.content.Context;
import android.graphics.Color;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.TextView;
import org.giletsjaunes.compteur.R;
import org.giletsjaunes.compteur.Region;
import java.util.List;


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Cellule du TableView des régions
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
public class RegionListViewAdapter extends ArrayAdapter<Region> {

    private final Context context;


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // constructeur
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public RegionListViewAdapter(Context context, int resourceId,
                                 List<Region> items) {
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
        Region region = getItem(position);

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
        holder.txtTitle.setText(region.nom);
        //holder.txtTitle.setTextColor(Color.rgb(44, 93, 205));
        //holder.txtTitle.setTypeface(Typeface.createFromAsset(context.getAssets(), "font/helvetica-neue-medium.ttf"));

        // compteur
        holder.txtCompteur.setText(region.nombre_total);

        if(region.id.equalsIgnoreCase("-1") || region.id.equalsIgnoreCase("-2")) {
            holder.txtTitle.setTextColor(Color.rgb(0, 0, 0));
        }
        else {
            holder.txtTitle.setTextColor(Color.rgb(0x33, 0x66, 0xff));
        }

            return convertView;
    }


    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // getItemId
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    public long getItemId(int position) {
        return position;
    }

}