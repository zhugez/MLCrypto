pragma solidity ^0.4.10; 
//Ezlab 2016 all-rights reserved support@ezlab.it
//special purpose contract for CantinaVolpone further info https://agrichain.it/d/0x160564d346f6e9fb3d93c034f207ecf9791b7739
//v.1609rev17042701 some optimization for costreduction
//common base contract
contract BaseAgriChainContract {
    address creator; 
    bool public isSealed;
    function BaseAgriChainContract() public    {  creator = msg.sender; EventCreated(this,creator); }
    modifier onlyIfNotSealed() //semantic when sealed is not possible to change sensible data
    {
        if (isSealed)
            throw;
        _;
    }

    modifier onlyBy(address _account) //semantic only _account can operate
    {
        if (msg.sender != _account)
            throw;
        _;
    }
    
    function kill() onlyBy(creator)   { suicide(creator); }     
    function setCreator(address _creator)  onlyBy(creator)  { creator = _creator;     }
    function setSealed()  onlyBy(creator)  { isSealed = true;  EventSealed(this);   } //seal down contract not reversible

    event EventCreated(address self,address creator);
    event EventSealed(address self); //invoked when contract is sealed
    event EventChanged(address self,string property); // generic property change
    event EventChangedInt32(address self,string property,int32 value); //Int32 property change
    event EventChangedString(address self,string property,string value); //string property Change
    event EventChangedAddress(address self,string property,address value); //address property Changed
    
  
}


//ChainedContract
contract AgriChainContract   is BaseAgriChainContract    
{     string public AgriChainType;
      address public  AgriChainNextData;
      address public  AgriChainPrevData;
      address public  AgriChainRootData;
    
    function   AgriChainDataContract() public
    {
        AgriChainNextData=address(this);
        AgriChainPrevData=address(this);
        AgriChainRootData=address(this);
    }
    
     
      
      
      
    function setChain(string _Type,address _Next,address _Prev, address _Root)  onlyBy(creator)  
    {
         AgriChainType=_Type;
         AgriChainNextData=_Next;
         AgriChainPrevData=_Prev;
         AgriChainRootData=_Root;
         EventChanged(this,'Chain');
    }
    
     function setChainNext(address _Next)  onlyBy(creator)  
    {
         AgriChainNextData=_Next;
         EventChangedAddress(this,'ChainNext',_Next);
    }
   

    function setChainPrev(address _Prev)  onlyBy(creator)  
    {
         AgriChainPrevData=_Prev;
         EventChangedAddress(this,'ChainNext',_Prev);
    }
    
   
   function setChainRoot(address _Root)  onlyBy(creator)  
    {
         AgriChainRootData=_Root;
         EventChangedAddress(this,'ChainRoot',_Root);
    }
    
     function setChainType(string _Type)  onlyBy(creator)  
    {
         AgriChainType=_Type;
         EventChangedString(this,'ChainType',_Type);
    }
      
}


// Master activities 
contract AgriChainMasterContract   is AgriChainContract    
{  
    address public  AgriChainContext;  //Context Data Chain
    address public  AgriChainCultivation;  //Cultivation Data Chain
    address public  AgriChainProduction;   //Production Data Chain
    address public  AgriChainDistribution; //Distribution Data Chain
    address public  AgriChainDocuments; //Distribution Data Chain

    function   AgriChainMasterContract() public
    { 
       AgriChainContext=address(this);
       AgriChainCultivation=address(this);
       AgriChainProduction=address(this);
       AgriChainDistribution=address(this);
       
    }
    function setAgriChainProduction(address _AgriChain)  onlyBy(creator) onlyIfNotSealed()
    {
         AgriChainProduction = _AgriChain;
         EventChangedAddress(this,'AgriChainProduction',_AgriChain);
    }
    function setAgriChainCultivation(address _AgriChain)  onlyBy(creator) onlyIfNotSealed()
    {
         AgriChainCultivation = _AgriChain;
         EventChangedAddress(this,'AgriChainCultivation',_AgriChain);
    }
    function setAgriChainDistribution(address _AgriChain)  onlyBy(creator) onlyIfNotSealed()
    {
         AgriChainDistribution = _AgriChain;
         EventChangedAddress(this,'AgriChainDistribution',_AgriChain);
    }
    
    function setAgriChainDocuments(address _AgriChain)  onlyBy(creator) onlyIfNotSealed()
    {
         AgriChainDocuments = _AgriChain;
         EventChangedAddress(this,'AgriChainDocuments',_AgriChain);
    }
    function setAgriChainContext(address _AgriChain)  onlyBy(creator) onlyIfNotSealed()
    {
         AgriChainContext = _AgriChain;
         EventChangedAddress(this,'AgriChainContext',_AgriChain);
    }
    
}



// legacy production contract 
contract AgriChainProductionContract   is BaseAgriChainContract    
{  
    string  public  Organization;      //Production Organization
    string  public  Product ;          //Product
    string  public  Description ;      //Description
    address public  AgriChainData;     //ProductionData
    string  public  AgriChainSeal;     //SecuritySeal
    string  public  Notes ;
    
    function   AgriChainProductionContract() public
    { 
       AgriChainData=address(this);
    }
    
    function setOrganization(string _Organization)  onlyBy(creator)  onlyIfNotSealed()
    {
          Organization = _Organization;
          EventChangedString(this,'Organization',_Organization);

    }
    
    function setProduct(string _Product)  onlyBy(creator) onlyIfNotSealed()
    {
          Product = _Product;
          EventChangedString(this,'Product',_Product);
        
    }
    
    function setDescription(string _Description)  onlyBy(creator) onlyIfNotSealed()
    {
          Description = _Description;
          EventChangedString(this,'Description',_Description);
    }
    function setAgriChainData(address _AgriChainData)  onlyBy(creator) onlyIfNotSealed()
    {
         AgriChainData = _AgriChainData;
         EventChangedAddress(this,'AgriChainData',_AgriChainData);
    }
    
    
    function setAgriChainSeal(string _AgriChainSeal)  onlyBy(creator) onlyIfNotSealed()
    {
         AgriChainSeal = _AgriChainSeal;
         EventChangedString(this,'AgriChainSeal',_AgriChainSeal);
    }
    
    
     
    function setNotes(string _Notes)  onlyBy(creator)
    {
         Notes =  _Notes;
         EventChanged(this,'Notes');
    }
}



//LoggedData
contract AgriChainDataContract   is AgriChainContract    
{  
      string public AgriChainLabel;
      string public AgriChainLabelInt;
      string public AgriChainDescription;
      string public AgriChainDescriptionInt;
      
    
    //main language data  
    function setData(string _Label,string _Description)  onlyBy(creator) onlyIfNotSealed()
    {
         
          AgriChainLabel=_Label;
          AgriChainDescription=_Description;
          EventChanged(this,'Data');
    }
   
    //International language data
    function setDataInt(string _LabelInt,string _DescriptionInt)  onlyBy(creator) onlyIfNotSealed()
    {
          
          AgriChainLabelInt=_LabelInt;
          AgriChainDescriptionInt=_DescriptionInt;
          EventChanged(this,'DataInt');
    }
   
      
}

//External DocumentData
//the extenal document is hashed  and chained as described by this contract
contract AgriChainDocumentContract   is AgriChainDataContract    
{  
     
    string  public  Emitter;      //Organization

    string  public  Name;         //Name
    string  public  NameInt;         //Name International

    string  public  FileName;     //FileName
    string  public  FileHash;     //FileHash
    string  public  FileData;     //FileData
   
    string  public  FileNameInt;  //FileName International
    string  public  FileHashInt;  //FileHash International
    string  public  FileDataInt;  //FileData International

    string  public  Notes ;
    address public  CurrentRevision; 
    
    function   AgriChainDocumentContract() public
    {
        CurrentRevision=address(this);
    }
    
    function setDocumentData(string _Emitter,string _Name, string _FileName,string _FileHash,string _FileData)  onlyBy(creator) onlyIfNotSealed()
    {
          Emitter=_Emitter;
          Name=_Name;
          FileName=_FileName;
          FileHash=_FileHash;
          FileData=_FileData;          
          EventChanged(this,'setDocumentData');
       
    } 
    
    function setCurrentRevision(address _Revision)  onlyBy(creator)  
    {
          CurrentRevision = _Revision;
          EventChangedAddress(this,'CurrentRevision',_Revision);
        
    } 
     
     
    function setNotes(string _Notes)  onlyBy(creator)
    {
         Notes =  _Notes;
         
    }
}


//Production Quntity counter contract
//the spedified production si accounted by this contract
contract AgriChainProductionLotContract   is AgriChainDataContract    
{  
    
     int32  public QuantityInitial;
     int32  public QuantityAvailable;
     string public QuantityUnit;
    
    function InitQuantity(int32 _Initial,string _Unit)  onlyBy(creator)  onlyIfNotSealed()
    {
          QuantityInitial = _Initial;
          QuantityAvailable = _Initial;
          QuantityUnit = _Unit;
          EventChangedInt32(this,'QuantityInitial',_Initial);

    }
  
    function UseQuantity(int32 _Use)  onlyBy(creator)  
    {
          QuantityAvailable = QuantityAvailable-_Use;
          EventChangedInt32(this,'QuantityAvailable',QuantityAvailable);

    }
  
}
