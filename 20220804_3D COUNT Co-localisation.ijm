voxel_depth=0.333333;//Z-stack differenc = voxeldepth
defaultThresh=newArray(4,0,0,0); //In the order of the setup made 
ThresForComparison=newArray(20,4,13,4); //In the order of the image channels
defaultChannelNames= newArray("DAPI","LAMP2","REC","ATPS");
//Set a standard option for the 3d counting toolID
run("3D OC Options", "volume surface nb_of_obj._voxels nb_of_surf._voxels integrated_density mean_gray_value std_dev_gray_value"+
" median_gray_value minimum_gray_value maximum_gray_value centroid mean_distance_to_surface std_dev_distance_to_surface median_distance_to_surface"+
" centre_of_mass bounding_box close_original_images_while_processing_(saves_memory) dots_size=5 font_size=10"+
" show_numbers white_numbers store_results_within_a_table_named_after_the_image_(macro_friendly) redirect_to=none");

//Open a Folder with exported TIFF images (unaltered 16bit) First image: Brighfield, second image: 488 FLuor
 input = getDirectory("Input directory");
 parent = File.getParent(input);
folder= File.getName(input);
list = getFileList(input);
//Create an opening diaologue
Dialog.create("Channels");
Dialog.addNumber("How Many channels your images have: ",4);
Dialog.show();
noOfChannel= Dialog.getNumber();

Dialog.create("Channels and Threshold");
for(i=0; i<noOfChannel;i++){
Dialog.addString("Channel "+(i+1), defaultChannelNames[i]);
}
Dialog.addChoice("Select first element to analyze", list);
Dialog.show();
firstElement= Dialog.getChoice();
channelNames= newArray(noOfChannel+1);
for(i=0; i<noOfChannel;i++){
	temp=Dialog.getString();
	
channelNames[i]= ""+(i+1)+":"+temp;	
}


//check which one is first element
for(i=0;i<list.length;i++){
	if(list[i]==firstElement){
		firstElementNumber=i;
	}
}

//
Dialog.create("Channels to Analyze");
channelNames[channelNames.length]= "None";
default=newArray(channelNames[3],channelNames[channelNames.length-1], channelNames[channelNames.length-1], channelNames[channelNames.length-1]);

for(i=0; i<noOfChannel;i++){
	//Change default for generalization
Dialog.addChoice("Analyze Channel " + (i+1)+":", channelNames, default[i]);
Dialog.addNumber("Set the Threshold for Channel: ", defaultThresh[i]);
}

Dialog.addNumber("Photoreceptors are in Channel ", 3);
Dialog.addNumber("General Organoid use channel ", 3);

Dialog.show();
channelSetup= newArray(noOfChannel);
threshold= newArray(noOfChannel);
for(i=0; i<noOfChannel;i++){
	//Change default for generalization
channelSetup[i]= Dialog.getChoice();
threshold[i]=Dialog.getNumber();
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////
channelSetup[channelSetup.length]=Dialog.getNumber();
channelSetup[channelSetup.length]=Dialog.getNumber();

//Open a Folder with exported TIFF images (unaltered 16bit), starting with first Element number of intro
for (k = firstElementNumber; k < list.length; k++) {
if (endsWith(list[k], ".tif") ){
	

//open Reference image ChannelSetup saved as last number
subNameCh= substring(channelSetup[channelSetup.length-1], 0, 1);

open(input+list[k+subNameCh-1]);
image1= getImageID();
run("Z Project...", "projection=[Max Intensity]");
image2= getImageID();
selectImage(image1);
close();
selectImage(image2);



//User Input= Draw a circle by hand
xpoints_ref=newArray();
ypoints_ref=newArray();
setTool("freehand");
selectionCorrect=false;
message1="Draw The whole Organoid. ";
while(selectionCorrect==false){
waitForUser(message1+"Draw a circle using the FREEHAND tool");

if(Roi.size>0&&selectionType==3){
	Roi.getCoordinates(xpoints_ref, ypoints_ref);
selectionCorrect=true;

} else {
message1= "Selection was not correct. Please Repeat. ";	
setTool("freehand");
}
}
close();
//User Input= Draw a circle by hand, coordinates saved in xpoints_ref and ypoints_ref

//////////////////////////////////////////////open PRC image, secondReference
subNameCh= substring(channelSetup[channelSetup.length-2], 0, 1);

open(input+list[k+subNameCh-1]);
image1=getImageID();
run("Z Project...", "projection=[Max Intensity]");
image2= getImageID();
selectImage(image1);
close();
selectImage(image2);

//User Input= Draw a circle by hand
xpoints_PRC=newArray();
ypoints_PRC=newArray();
setTool("freehand");
selectionCorrect=false;
message1="Draw The PRC Area. ";
while(selectionCorrect==false){
waitForUser(message1+"Draw a circle using the FREEHAND tool");

if(Roi.size>0&&selectionType==3){
selectionCorrect=true;
Roi.getCoordinates(xpoints_PRC, ypoints_PRC);
} else {
message1= "Selection was not correct. Please Repeat. ";	
setTool("freehand");
}
}
close();
//User Input= Draw a circle by hand, coordinates saved in xpoints_PRC and ypoints_PRC

//The two setups Whole organoids and PRC are selected here
selectedArea=newArray("Whole","PRC");
//Loop for the number of channels to be analyzed; if channelSetup for this was none then it will not be analyzed
for(l=0; l<noOfChannel;l++){
	if(channelSetup[l]!="None"){
		for(o=0; o<selectedArea.length;o++) {
subNameCh= substring(channelSetup[l], 0, 1);
		
open(input+list[k+subNameCh-1]);
//Number of Slices


sliceNumber=nSlices;
//Start with the selectoin of the whole organoid = REF
if(o==0){
Roi.setPolygonSplineAnchors(xpoints_ref, ypoints_ref);
} else {Roi.setPolygonSplineAnchors(xpoints_PRC, ypoints_PRC);
		}
run("Crop");
run("Clear Outside", "stack");
image1=getImageID();
width= getWidth();
height= getHeight();
run("Clear Results");
run("Measure");

run("Properties...", "voxel_depth="+voxel_depth);
run("Smooth", "stack");

run("3D Objects Counter", "threshold="+threshold[l]+" slice=8 min.=10 max.=67108864 exclude_objects_on_edges objects");
//run("3D Manager Options", "volume surface compactness fit_ellipse 3d_moments integrated_density std_dev_grey_value mode_grey_value feret minimum_grey_value maximum_grey_value distance_to_surface bounding_box sync distance_between_centers=10 distance_max_contact=1.80");
// run the manager 3D and add image
run("3D Manager");
Ext.Manager3D_Delete();
Ext.Manager3D_AddImage();
run("3D Manager");
Ext.Manager3D_DeselectAll();
// do some measurements, save measurements and close window

//for each other channel make a table/file
image2=getImageID();
//selectImage(image1);
//close();
selectImage(image2);
run("Z Project...", "projection=[Max Intensity]");
saveAs(parent+"//Max Obj 3d_"+selectedArea[o]+"_"+list[k+subNameCh-1]+".tif");
selectImage(image2);
close();
close();
run("3D Manager Options", "feret surface volume integrated_density mean_grey_value std_dev_grey_value mode_grey_value minimum_grey_value maximum_grey_value distance_between_centers=10 distance_max_contact=1.80 drawing=Contour");// run the manager 3D and add image

for(m=0; m<(noOfChannel);m++){
		
open(input+list[k+m]);
run("Properties...", "voxel_depth="+voxel_depth);
image2=getImageID();
if(o==0){
Roi.setPolygonSplineAnchors(xpoints_ref, ypoints_ref);
} else {Roi.setPolygonSplineAnchors(xpoints_PRC, ypoints_PRC);
		}
run("Crop");
run("Clear Outside", "stack");
run("Smooth", "stack");


bit= bitDepth();
maxPixel= Math.pow(2, bit)-1;
setThreshold(11, 255);
setThreshold(ThresForComparison[m], maxPixel);
//waitForUser;
setOption("BlackBackground", true);
run("Convert to Mask", "method=Default background=Dark black");
//waitForUser;
run("3D Manager");
Ext.Manager3D_Measure();
Ext.Manager3D_SaveResult("M",parent+"/-"+selectedArea[o]+"-Ch0"+m+"-"+list[k+m]+".csv");
Ext.Manager3D_CloseResult("M");
Ext.Manager3D_Quantif();
Ext.Manager3D_SaveResult("Q",parent+"/-"+selectedArea[o]+"-Ch0"+m+"-"+list[k+m]+".csv");
Ext.Manager3D_CloseResult("Q");
selectImage(image2);
close();
}


		}//Selcted Area "o" either whole or PRC
	}//	if(channelSetup[l]!="None"){
}//for(l=0; l<noOfChannel;l++){
k=k+noOfChannel-1;

}//if ends with tif
}//for loop for input list


