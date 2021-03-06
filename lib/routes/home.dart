import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

import '../size_config.dart';
import '../constants.dart';
import '../widgets/product_card/product_card.dart';
import '../widgets/product_card/product_card_gestures.dart';
import '../widgets/product_card/gesture_background.dart';
import '../widgets/drawer.dart';
import '../widgets/badge.dart';
import '../widgets/no_products_warning.dart';
import '../providers/products.dart';
import '../providers/cart.dart';
import '../providers/auth.dart';
import '../routes_handler.dart';

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final isAuth = Provider.of<Auth>(context, listen: false).isAuth;

    final appBar = AppBar(
      title: Text(shopName),
      actions: [
        isAuth
            ? Consumer<Cart>(
                builder: (_, cart, child) => Badge(
                  child: child,
                  value: cart.totalItemsCount,
                ),
                child: FlatButton(
                  child: Row(
                    children: [
                      Icon(Icons.shopping_bag),
                      Text('Sacolinha'),
                    ],
                  ),
                  onPressed: () => Navigator.pushNamed(context, cartItemsRoute),
                ),
              )
            : FlatButton(
                child: Text('ENTRAR OU CRIAR UMA CONTA'),
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed(welcomeRoute);
                },
              ),
      ],
    );

    return Scaffold(
      drawer: isAuth ? MainDrawer() : null,
      appBar: appBar,
      body: FutureBuilder(
        future: Provider.of<Products>(context, listen: false)
            .fetchProductsFromDatabase(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
                child: Lottie.asset('assets/animations/bouncy-balls.json'));
          } else {
            if (snapshot.hasError) {
              return Center(
                child: Text(snapshot.error),
              );
            }

            return Consumer<Products>(
              builder: (_, productsProvider, child) {
                final products = productsProvider.products;

                return LayoutBuilder(
                  builder: (_, constraints) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        await Provider.of<Products>(context, listen: false)
                            .fetchProductsFromDatabase()
                            .catchError((error) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (alertContext) => AlertDialog(
                              title: Text('Erro inesperado'),
                              content: Text(error, textAlign: TextAlign.center),
                              actions: [
                                FlatButton(
                                  child: Text('Entendi'),
                                  onPressed: () =>
                                      Navigator.of(alertContext).pop(),
                                ),
                              ],
                            ),
                          );
                        });
                      },
                      child: !productsProvider.hasAtLeastOneProduct
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Container(
                                height: constraints.maxHeight,
                                child: NoProductsWarning(),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(top: 0),
                              itemCount: products.length,
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (ctx, index) {
                                final product = products.elementAt(index);

                                return Consumer2<Products, Cart>(
                                  builder: (ctx, products, cart, child) {
                                    final isInCart = cart.contains(product);
                                    final isFavorite = product.isFavorite;
                                    final removeItem = cart.removeProduct;
                                    final addItem = cart.addProduct;

                                    return ProductCardGestures(
                                      key: ValueKey<String>(product.id),
                                      child: ProductCard(
                                        product,
                                        icons: _getIcons(
                                          isFavorite: isFavorite,
                                          isInCart: isInCart,
                                        ),
                                      ),
                                      onTap: () =>
                                          Navigator.of(context).pushNamed(
                                        productOverviewRoute,
                                        arguments: product,
                                      ),
                                      onDoubleTap: () {
                                        try {
                                         return products
                                              .toggleFavoriteStatus(product);
                                        } catch (error) {
                                          Scaffold.of(ctx)
                                              .hideCurrentSnackBar();
                                          Scaffold.of(ctx).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                error,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      onRightSwipe: () {
                                        if (isInCart) {
                                          removeItem(product);
                                          _showSnackbar(
                                              ctx,
                                              'Removido da sacolinha!',
                                              () => addItem(product));
                                        } else {
                                          addItem(product);
                                          _showSnackbar(
                                            ctx,
                                            'Salvo na sacolinha!',
                                            () => removeItem(product),
                                          );
                                        }
                                      },
                                      rightSwipeBackground: isInCart
                                          ? GestureBackground(
                                              icon: Icons.shopping_bag,
                                              label: 'Remover da sacolinha',
                                              color: const Color(0xFFF5C6BC),
                                              backgroundColor:
                                                  const Color(0xFFF2804E),
                                              alignment: Alignment.centerLeft,
                                            )
                                          : GestureBackground(
                                              icon: Icons.shopping_bag,
                                              label: 'Salvar na sacolinha',
                                              color: const Color(0xFFF5BCE4),
                                              backgroundColor:
                                                  Theme.of(context).accentColor,
                                              alignment: Alignment.centerLeft,
                                            ),
                                    );
                                  },
                                );
                              },
                            ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}

void _showSnackbar(BuildContext context, String label, VoidCallback onPressed) {
  final scaffold = Scaffold.of(context);
  scaffold.hideCurrentSnackBar();
  scaffold.showSnackBar(
    SnackBar(
      content: Text(label),
      duration: Duration(seconds: 2),
      action: SnackBarAction(
        label: 'DESFAZER',
        onPressed: onPressed,
        textColor: Theme.of(context).primaryColor,
      ),
    ),
  );
}

List<Widget> _getIcons({bool isFavorite, bool isInCart}) {
  final List<Widget> icons = [];

  if (isInCart) {
    icons.add(Icon(Icons.shopping_bag, color: const Color(0xFFF56713)));
    icons.add(SizedBox(width: 10));
  }

  if (isFavorite) {
    icons.add(Icon(Icons.favorite, color: Colors.pink));
    icons.add(SizedBox(width: 10));
  }

  return icons;
}
