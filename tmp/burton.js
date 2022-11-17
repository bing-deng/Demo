// ==UserScript==
// @name         Buerton
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  try to take over the world!
// @author       You
// @match        https://www.burton.com/jp/ja/*
// @icon         data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==
// @grant        none
// ==/UserScript==

const sleep = msec => new Promise(resolve => setTimeout(resolve, msec));
// test url from https://www.burton.com/jp/ja/c/anon-optics-goggles-1?start=0&sz=24
// https://www.burton.com/jp/ja/p/anon-m4s-toric-low-bridge-goggles--bonus-lens/W23JP-235751.html?cgid=anon-optics-goggles
// https://www.burton.com/jp/ja/cart
(function() {
     'use strict';

    console.log(document.location.href.indexOf("burton.com/jp/ja/p/" != -1))
    if(document.location.href.indexOf("https://www.burton.com/jp/ja/shipping")!=-1){
        document.getElementById("dwfrm_shipping_email").value = "Cloyd.Torphy36@gmail.com"
        document.getElementById("dwfrm_shipping_shippingAddress_addressFields_lastName").value = "Koepp"
        document.getElementById("dwfrm_shipping_shippingAddress_addressFields_firstName").value = "Geo"
        document.getElementById("dwfrm_shipping_shippingAddress_addressFields_lastNamePronunciation").value = "Koepp"
        document.getElementById("dwfrm_shipping_shippingAddress_addressFields_firstNamePronunciation").value = "Geo"
        document.getElementById("dwfrm_shipping_shippingAddress_addressFields_postalCode").value = "1350016"
        document.getElementById("dwfrm_shipping_shippingAddress_addressFields_city").value = "市区町村"
        document.getElementById("dwfrm_shipping_shippingAddress_addressFields_address1").value = "東京都板橋区"
        //
        document.getElementsByTagName("select")[0].selectedIndex = 8
        document.getElementById("dwfrm_shipping_shippingAddress_addressFields_address2").value = "二丁目7番10号"
        document.getElementById("dwfrm_shipping_shippingAddress_addressFields_phone").value = "080 1234 3211"


     }else if(document.location.href.indexOf("https://www.burton.com/jp/ja/cart")!=-1){

         (async () => {
             console.log('スタート shopCar');
              while(true){
                  console.log("222")
                  var goToLenji = document.getElementsByClassName("secure-checkout-btn")
                  if(goToLenji.length > 0){
                     //购物车页面跳转结账页面 レジ
                      goToLenji[1].click()
                      break
                  }
                  await sleep(1000);
              }
             console.log('1秒経ってる!')
         })();


     }else if(document.location.href.indexOf("burton.com/jp/ja/p/" != -1)){
         // Your code here...
         // 0:s 1:M 2:L 3:XL

         var size = document.getElementsByClassName("variant-swatch variationSize background")
         if(size.length > 0){
            document.getElementsByClassName("variant-swatch variationSize background")[1].click()
         }

         const sleep = msec => new Promise(resolve => setTimeout(resolve, msec));

         (async () => {
             console.log('スタート shopCar');
              while(true){
                  console.log("222")
                  var shopCar = document.getElementsByClassName("in-stock")
                  if(shopCar.length > 0){
                      //添加购物车
                      document.getElementsByClassName("in-stock")[0].click()
                      console.log("hhh")
                      break
                  }
                  await sleep(1000);
              }
             console.log('1秒経ってる!')
         })();

          (async () => {
             console.log('スタート shopCar');
              while(true){
                  console.log("222")
                  var lenji = document.querySelector("#js-vue-teleport > div.modal.modal--open.modal--add-to-cart-interstitial > div.modal__content.modal__content--standard > div > div.add-to-cart-block > section > div.product-actions > a")
                  if(lenji != undefined){
                      //添加购物车
                      lenji.click()
                      console.log("kkk")
                      break
                  }
                  await sleep(1000);
              }
             console.log('1秒経ってる!')
         })();



        // window.location = "https://www.burton.com/jp/ja/cart"




         // 进到购物车 // https://www.burton.com/jp/ja/cart
         //document.getElementsByClassName("btn")[1].click()

     }


})();
